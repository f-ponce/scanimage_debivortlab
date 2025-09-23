classdef ESP301 < handle
    % Legacy Stage Controller (LSC) for Newport ESP301 (multi-axis)
    % Works with scanimage.components.motors.legacy.StageController.

    %% ===== Public config =====
    properties
        comPort                         % integer (e.g., 6 for COM6)
        axes  char = '123'              % axes to control: any subset of '123'
        velocity = 0.5                  % scalar or 1xN; controller units/s
        accel    = 0.3                  % scalar or 1xN; controller units/s^2
        decel    = 0.3                  % scalar or 1xN; controller units/s^2
        baud     = 921600               % 921600 or 115200 for ESP301
        timeout_s   = 2.0               % I/O timeout (s)
        moveTimeout = 10.0              % seconds
        numDeviceDimensions = 1         % set from axes in ctor
        travelRange = [NaN NaN]         % unused for non-analog LSCs
    end

    %% ===== Required by StageController =====
    properties (SetAccess=private)
        lscErrPending = false
        nonblockingMoveInProgress = false
        activeDimensions                          % logical [1 x numDeviceDimensions]
        lastTargetPosition = []                   % [1 x numDeviceDimensions]
        relativeOrigin     = []                   % [1 x numDeviceDimensions]
        isMoving = false
        resolution = NaN
        resolutionBest = NaN
    end

    properties (Dependent)
        positionAbsolute                          % [1 x numDeviceDimensions]
        positionRelative
    end

    %% ===== Internals =====
    properties (Access=private)
        sp                         % serialport
        eol = "CR/LF";             % default; auto-fallback to "CR"
        tMove timer = timer.empty  % timer handle
        triedAltEol = false
    end

    %% ===== Lifecycle =====
    methods
        function obj = ESP301(varargin)
            if mod(nargin,2)~=0, error('ESP301: use name/value pairs'); end
            for k=1:2:numel(varargin)
                n = varargin{k}; v = varargin{k+1};
                if isprop(obj,n), obj.(n) = v; end
            end

            % Normalize axes and set dimension count
            obj.axes = char(obj.axes(:).');                   % row char, e.g. '123'
            obj.numDeviceDimensions = numel(obj.axes);
            obj.activeDimensions = true(1, obj.numDeviceDimensions);

            % Normalize motion params to 1xN vectors
            obj.velocity = obj.expandToN(obj.velocity);
            obj.accel    = obj.expandToN(obj.accel);
            obj.decel    = obj.expandToN(obj.decel);

            % ---- open & configure hardware ----
            assert(~isempty(obj.comPort), 'ESP301: set ''comPort'' (integer).');
            comStr = sprintf('COM%d', obj.comPort);

            try, avail = serialportlist("available"); catch, avail = {}; end
            if ~isempty(avail) && ~ismember(comStr, avail)
                error('ESP301: Port %s not found. Available: %s', comStr, strjoin(avail, ', '));
            end

            obj.sp = serialport(comStr, obj.baud, 'Timeout', obj.timeout_s);
            configureTerminator(obj.sp, obj.eol);
            flush(obj.sp);

            % Enable each axis, set trajectory and profile
            for i = 1:obj.numDeviceDimensions
                ax = obj.axes(i);
                obj.command([ax 'MO']);
                obj.ensureTrajectory(ax);  % TJ1 or TJ2
                obj.setAxisProfile(ax, obj.velocity(i), obj.accel(i), obj.decel(i));
            end

            obj.clearLastError();

            % Prime position cache (best-effort)
            try %#ok<TRYNC>
                ~obj.positionAbsolute; %#ok<VUNUS>
            end
        end

        function delete(obj)
            obj.stopMoveTimer();
            try
                if ~isempty(obj.sp)
                    flush(obj.sp);
                    clear obj.sp; %#ok<CLPUR>
                end
            catch
            end
        end
    end

    %% ===== Methods StageController calls =====
    methods
        function reinitMotor(obj) %#ok<MANU>
            % StageController constructs an initialized LSC.
        end

        function moveStartAbsolute(obj, position, cbk)
            % position: 1xN vector in controller units; NaN leaves axis unchanged
            pos = obj.vecN(position);
            obj.lastTargetPosition = pos;

            % Issue PA for each axis that has a finite target
            for i = 1:obj.numDeviceDimensions
                if ~isnan(pos(i))
                    ax = obj.axes(i);
                    obj.ensureTrajectory(ax);
                    obj.cmdf('%sPA%0.9f', ax, pos(i));
                end
            end

            obj.isMoving = true;
            obj.nonblockingMoveInProgress = true;

            % Optional immediate fault surfacing
            try
                te = strtrim(obj.q('TE?'));
                if ~strcmp(te,'0'), obj.throwWithTB('Error after PA'); end
            catch
            end

            if nargin >= 3 && ~isempty(cbk) && isa(cbk,'function_handle')
                obj.startMoveTimer(cbk);
            end
        end

        function moveWaitForFinish(obj, timeout_s)
            if nargin < 2 || isempty(timeout_s), timeout_s = obj.moveTimeout; end
            t0 = tic;
            try
                while obj.queryIsMovingAny()
                    pause(0.01);
                    if toc(t0) > timeout_s
                        obj.moveCancel();
                        obj.throwWithTB('Move timeout after %.3fs', timeout_s);
                    end
                end
                obj.nonblockingMoveInProgress = false;
                pause(0.02);
                obj.clearLastError();
            catch ME
                obj.throwWithTB('Exception in moveWaitForFinish: %s', ME.message);
            end
        end

        function moveCompleteAbsolute(obj, position)
            obj.moveStartAbsolute(position);
            obj.moveWaitForFinish(obj.moveTimeout);
        end

        function moveCancel(obj)
            obj.stopMoveTimer();
            obj.cmd('ST');  % stops all axes
            obj.isMoving = false;
            obj.nonblockingMoveInProgress = false;
            try
                te = strtrim(obj.q('TE?'));
                if ~strcmp(te,'0'), obj.throwWithTB('After ST (stop)'); end
            catch
            end
        end

        function reset(obj, varargin),   obj.clearLastError(); end %#ok<INUSD>
        function recover(obj, varargin), obj.clearLastError(); end %#ok<INUSD>

        function abspos = relativeToAbsoluteCoords(obj, rel)
            cur = obj.positionAbsolute;
            rel = obj.vecN(rel);
            abspos = cur + rel;
            if ~isempty(obj.relativeOrigin)
                % If a soft origin is set, rel was intended in that frame
                abspos = obj.vecN(obj.relativeOrigin) + rel;
            end
        end

        function zeroSoft(obj, coords)
            if nargin < 2 || isempty(coords)
                obj.relativeOrigin = obj.positionAbsolute;
            else
                obj.relativeOrigin = obj.vecN(coords);
            end
        end

        function clearSoftZero(obj), obj.relativeOrigin = []; end

        function zeroHard(obj, varargin) %#ok<INUSD>
            error('ESP301: zeroHard not implemented on this LSC.');
        end
    end

    %% ===== Dependent props =====
    methods
        function v = get.positionAbsolute(obj)
            v = nan(1, obj.numDeviceDimensions);
            for i = 1:obj.numDeviceDimensions
                ax = obj.axes(i);
                vi = str2double(obj.q(sprintf('%sTP?', ax)));
                if ~isfinite(vi), vi = str2double(obj.q(sprintf('%sTP', ax))); end
                v(i) = vi;
            end
        end

        function v = get.positionRelative(obj)
            abspos = obj.positionAbsolute;
            if isempty(obj.relativeOrigin)
                v = abspos;
            else
                v = abspos - obj.vecN(obj.relativeOrigin);
            end
        end
    end

    %% ===== Internals =====
    methods (Access=private)
        
        function s = safeQuery(obj, cmdstr)
            % Quietly try a query; return '' on any error/time-out.
            try
                s = strtrim(obj.q(cmdstr));
            catch
                s = '';
            end
        end

        function tf = queryIsMovingAny(obj)
            % Prefer per-axis MD? (0=in progress, 1=done). If any axis reports 0, still moving
            anyMoving = false; ok = false;
            for i = 1:obj.numDeviceDimensions
                ax = obj.axes(i);
                s = obj.q(sprintf('%sMD?', ax));
                md = str2double(regexprep(char(s),'[^\d\.\-+]',''));
                if isfinite(md), ok = true; anyMoving = anyMoving || (md == 0); end
            end
            if ok
                tf = anyMoving;
                obj.isMoving = tf;
                return;
            end

            % Fallback: TS status byte(s). First byte covers axes 1..4
            st = obj.q('TS');
            if isempty(st)
                tf = false;
            else
                b = uint8(st(1));
                moving = false(1,obj.numDeviceDimensions);
                for i = 1:obj.numDeviceDimensions
                    axIdx = str2double(obj.axes(i));    % '1'->1, etc.
                    % Treat bit==1 as "moving" for that axis index
                    moving(i) = bitget(b, axIdx) ~= 0;
                end
                tf = any(moving);
            end
            obj.isMoving = tf;
        end

        function ensureTrajectory(obj, ax)
            % Ensure valid trajectory (TJ1 or TJ2) for given axis char
            t = str2double(obj.q(sprintf('%sTJ?', ax)));
            if ~(t==1 || t==2)
                obj.command([ax 'TJ2']); % prefer S-curve
                t2 = str2double(obj.q(sprintf('%sTJ?', ax)));
                if ~(t2==1 || t2==2)
                    error('ESP301: failed to set valid trajectory (TJ) for axis %s.', ax);
                end
            end
        end

        function setAxisProfile(obj, ax, vel, acc, dec)
            vel = max(vel, 0.05); acc = max(acc, 0.05); dec = max(dec, 0.05);
            obj.command(sprintf('%sAG%0.6f', ax, dec));  % decel first
            obj.command(sprintf('%sAC%0.6f', ax, acc));  % then accel
            obj.command(sprintf('%sVA%0.6f', ax, vel));  % then velocity
            obj.safeQuery('TE?'); obj.safeQuery('TB?');
        end

        function clearLastError(obj)
            e = str2double(obj.q('TE?'));
            obj.lscErrPending = isfinite(e) && (e ~= 0);
        end

        function startMoveTimer(obj, cbk)
            obj.stopMoveTimer();
            obj.tMove = timer('ExecutionMode','fixedSpacing','Period',0.03, ...
                              'TimerFcn', @(~,~) obj.pollDone(cbk), ...
                              'StartDelay', 0.05);
            start(obj.tMove);
        end

        function stopMoveTimer(obj)
            if ~isempty(obj.tMove)
                try, stop(obj.tMove);  catch, end
                try, delete(obj.tMove); catch, end
                obj.tMove = timer.empty;
            end
        end

        function pollDone(obj, cbk)
            if ~obj.queryIsMovingAny()
                obj.stopMoveTimer();
                obj.nonblockingMoveInProgress = false;
                try, cbk(); catch, end
            end
        end

        function cmd(obj, s)
            writeline(obj.sp, s);
        end

        function cmdf(obj, fmt, varargin)
            obj.cmd(sprintf(fmt, varargin{:}));
        end

        function out = q(obj, cmdstr)
            flush(obj.sp);
            writeline(obj.sp, cmdstr);
            s = obj.safeReadline();
            if s == ""
                if ~obj.triedAltEol
                    obj.triedAltEol = true;
                    try
                        if strcmpi(obj.eol,"CR/LF")
                            configureTerminator(obj.sp, "CR");  obj.eol = "CR";
                        else
                            configureTerminator(obj.sp, "CR/LF"); obj.eol = "CR/LF";
                        end
                        s = obj.safeReadline();
                    catch
                    end
                end
            end
            if s == ""
                error('ESP301: no response to "%s" at %s, %d baud (timeout=%.2fs; EOL=%s).', ...
                      cmdstr, obj.sp.Port, obj.baud, obj.timeout_s, obj.eol);
            end
            out = char(strtrim(s));
        end

        function s = safeReadline(obj)
            warnID = 'MATLAB:serialport:readline:unsuccessfulRead';
            ws = warning('query', warnID);
            warning('off', warnID);
            c = onCleanup(@() warning(ws.state, warnID)); %#ok<NASGU>
            try
                raw = readline(obj.sp);
                s = string(raw); if isempty(raw), s = ""; end
            catch
                s = "";
            end
        end

        function v = vecN(obj, x)
            % Return 1xN vector aligned to axes; NaN for missing entries
            N = obj.numDeviceDimensions;
            v = nan(1,N);
            if isempty(x), return; end
            x = double(x); x = x(:).';
            v(1:min(N,numel(x))) = x(1:min(N,numel(x)));
        end

        function arr = expandToN(obj, a)
            N = obj.numDeviceDimensions;
            if isscalar(a), arr = repmat(a,1,N);
            else, a = a(:).'; assert(numel(a)==N,'Provide 1 or %d values.',N); arr = a;
            end
        end

        % ---- Error reporting helpers ----
        function [te,tb] = readErrorLines(obj)
            te = '?'; tb = '?';
            try, te = strtrim(obj.q('TE?')); catch, end
            try, tb = strtrim(obj.q('TB?')); catch, end
            obj.lscErrPending = ~strcmp(te,'0');
        end

        function throwWithTB(obj, contextFmt, varargin)
            if nargin < 2, contextFmt = 'ESP301 error'; end
            context = sprintf(contextFmt, varargin{:});
            [te,tb] = obj.readErrorLines();
            msg = sprintf('[ESP301] %s | TE?=%s | TB?=%s', context, te, tb);
            try, fprintf(2, '%s\n', msg); catch, end
            ME = MException('scanimage:motors:ESP301', '%s', msg);
            throwAsCaller(ME);
        end
    end

    %% ----- Public wrappers (handy for console testing) -----
    methods
        function out = query(obj, cmdstr),   out = obj.q(cmdstr); end
        function command(obj, cmdstr),       obj.cmd(cmdstr); end
    end
end
