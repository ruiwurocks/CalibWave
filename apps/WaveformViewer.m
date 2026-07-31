classdef WaveformViewer < matlab.apps.AppBase

    properties
        UIFigure
        UIAxes

        LoadWaveformDBButton
        SensorModeDropDown
        GroupModeDropDown
        SensorListBox
        BallSizeDropDown
        ShowTheoryCheckBox
        ShowRawCheckBox
        PlotButton
        ZoomXButton
        ZoomYButton
        PanButton

        WaveformDB
        PlotData
        ZoomMode = "X"

        XMin_us = -100
        XMax_us = 200
        ViewXLim = [-100 200]

        IsPanning = false
        PanStartPoint
        PanStartXLim
        ResetYOnRefresh = true
        ViewYLimLeft = []
        ViewYLimRight = []
        FFTButton
        FFTApp = []
        ExportCurrentButton
        ExportAllButton
        ExportTypeDropDown
        SensitivityButton
    end

    methods

        function app = WaveformViewer(WaveformDB)
            createComponents(app);
            if nargin >= 1 && ~isempty(WaveformDB)
                app.setWaveformDB(WaveformDB);
                app.plotWaveforms();
            end
        end

        function createComponents(app)

            app.UIFigure = uifigure('Name','Waveform Viewer');
            app.UIFigure.Position = [100 100 1100 650];
            app.UIFigure.WindowScrollWheelFcn = @(src,event) mouseWheelZoom(app,event);
            app.UIFigure.WindowButtonDownFcn = @(src,event) startPan(app);
            app.UIFigure.WindowButtonMotionFcn = @(src,event) doPan(app);
            app.UIFigure.WindowButtonUpFcn = @(src,event) stopPan(app);

            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [80 80 930 470];
            app.UIAxes.Box = 'on';
            app.UIAxes.LineWidth = 1.2;
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';

            app.LoadWaveformDBButton = uibutton(app.UIFigure,'push', ...
                'Text','Load WaveformDB', ...
                'Position',[50 590 160 30], ...
                'ButtonPushedFcn',@(src,event) loadWaveformDB(app));

            app.SensorModeDropDown = uidropdown(app.UIFigure, ...
                'Items',{'Single sensor','Multiple sensors'}, ...
                'Position',[235 590 150 30]);

            app.GroupModeDropDown = uidropdown(app.UIFigure, ...
                'Items',{'Ball size','Capillary fracture'}, ...
                'Position',[410 590 170 30], ...
                'Value','Ball size', ...
                'ValueChangedFcn',@(src,event) updateControlState(app));

            app.SensorListBox = uilistbox(app.UIFigure, ...
                'Items',{}, ...
                'Multiselect','on', ...
                'Position',[600 555 160 75]);

            app.BallSizeDropDown = uidropdown(app.UIFigure, ...
                'Items',{}, ...
                'Position',[780 590 100 30]);

            app.ShowTheoryCheckBox = uicheckbox(app.UIFigure, ...
                'Text','Theory', ...
                'Value',true, ...
                'Position',[900 590 90 30]);

            app.ShowRawCheckBox = uicheckbox(app.UIFigure, ...
                'Text','Raw repeats', ...
                'Value',false, ...
                'Position',[900 555 110 30]);

            app.PlotButton = uibutton(app.UIFigure,'push', ...
                'Text','Plot', ...
                'FontWeight','bold', ...
                'Position',[995 590 70 30], ...
                'ButtonPushedFcn',@(src,event) plotWaveforms(app));

            app.ZoomXButton = uibutton(app.UIFigure,'push', ...
                'Text','Zoom X', ...
                'Position',[795 515 70 30], ...
                'ButtonPushedFcn',@(src,event)setZoomMode(app,"X"));

            app.ZoomYButton = uibutton(app.UIFigure,'push', ...
                'Text','Zoom Y', ...
                'Position',[875 515 70 30], ...
                'ButtonPushedFcn',@(src,event)setZoomMode(app,"Y"));

            app.PanButton = uibutton(app.UIFigure,'push', ...
                'Text','Pan', ...
                'Position',[955 515 70 30], ...
                'ButtonPushedFcn',@(src,event)setZoomMode(app,"Pan"));

            app.setZoomMode("X");
            app.FFTButton = uibutton(app.UIFigure,'push',...
                'Text','FFT Viewer',...
                'FontWeight','bold',...
                'Position',[560 25 100 30],...
                'ButtonPushedFcn',@(src,event) openFFTViewer(app));

            app.ExportTypeDropDown = uidropdown(app.UIFigure,...
                'Items',{'pdf','jpg','png'},...
                'Value','pdf',...
                'Position',[680 25 80 30]);

            app.ExportCurrentButton = uibutton(app.UIFigure,'push',...
                'Text','Export Current',...
                'Position',[770 25 120 30],...
                'ButtonPushedFcn',@(src,event) exportCurrentWaveformFigure(app));

            app.ExportAllButton = uibutton(app.UIFigure,'push',...
                'Text','Export All',...
                'FontWeight','bold',...
                'Position',[900 25 110 30],...
                'ButtonPushedFcn',@(src,event) exportAllWaveformFigures(app));
        end

        function loadWaveformDB(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load WaveformDB.mat');
            if isequal(file,0); return; end

            data = load(fullfile(path,file));

            if ~isfield(data,'WaveformDB')
                uialert(app.UIFigure,'No WaveformDB found.','Load Error');
                return;
            end

            app.setWaveformDB(data.WaveformDB);
            app.plotWaveforms();
        end

        function setWaveformDB(app,WaveformDB)
            calibwave.config.validateWaveformDB(WaveformDB);
            app.WaveformDB = WaveformDB;

            SensorArray = app.WaveformDB.Config.SensorArray;
            labels = strings(numel(SensorArray),1);

            for i = 1:numel(SensorArray)
                labels(i) = sprintf('%s (%s)', ...
                    string(SensorArray(i).SensorLabel), ...
                    string(SensorArray(i).ChannelLabel));
            end

            app.SensorListBox.Items = cellstr(labels);
            if ~isempty(labels)
                app.SensorListBox.Value = app.SensorListBox.Items{1};
            end

            groupItems = {};
            if isfield(app.WaveformDB,'Ball') && ...
                    ~isempty(app.WaveformDB.Ball.Files)
                groupItems{end+1} = 'Ball size'; %#ok<AGROW>
                D = [];
                for i = 1:numel(app.WaveformDB.Ball.Files)
                    if isfield(app.WaveformDB.Ball.Files(i),'Ball')
                        D(end+1) = app.WaveformDB.Ball.Files(i).Ball.Diameter_mm; %#ok<AGROW>
                    end
                end
                D = unique(D(~isnan(D)));
                app.BallSizeDropDown.Items = cellstr(string(D));
                if ~isempty(D)
                    app.BallSizeDropDown.Value = string(D(1));
                end
            end

            if isfield(app.WaveformDB,'Capillary') && ...
                    ~isempty(app.WaveformDB.Capillary.Files)
                groupItems{end+1} = 'Capillary fracture'; %#ok<AGROW>
            end

            app.GroupModeDropDown.Items = groupItems;
            if ~isempty(groupItems)
                app.GroupModeDropDown.Value = groupItems{1};
            end
            app.updateControlState();
        end

        function updateControlState(app)
            if strcmp(app.GroupModeDropDown.Value,'Capillary fracture')
                app.BallSizeDropDown.Enable = 'off';
            else
                app.BallSizeDropDown.Enable = 'on';
            end
        end

        function plotWaveforms(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));
            app.updateControlState();
            app.closeFFTViewer();
            if isempty(app.WaveformDB)
                uialert(app.UIFigure,'Please load WaveformDB first.','Missing Data');
                return;
            end

            app.PlotData = struct();
            app.PlotData.ExpRaw = struct([]);
            app.PlotData.ExpAvg = struct([]);
            app.PlotData.Theory = struct([]);
            app.PlotData.Arrivals = [];
            app.PlotData.Title = "";


            switch app.GroupModeDropDown.Value
                case 'Ball size'
                    app.prepareBallPlotData();
                case 'Capillary fracture'
                    app.prepareCapillaryPlotData();
            end

            app.ViewXLim = [app.XMin_us app.XMax_us];
            app.ResetYOnRefresh = true;
            app.refreshVisiblePlot();
            app.ViewYLimLeft = [];
            app.ViewYLimRight = [];
            app.ResetYOnRefresh = true;
        end

        function prepareBallPlotData(app)

            DB = app.WaveformDB.Ball;
            Config = app.WaveformDB.Config;
            Fs = Config.DAQ.Fs;

            selectedSensorIDs = app.getSelectedSensorIDs();
            D_target = str2double(app.BallSizeDropDown.Value);

            isSingleSensor = strcmp(app.SensorModeDropDown.Value,'Single sensor');
            showRaw = app.ShowRawCheckBox.Value && isSingleSensor;

            for ss = selectedSensorIDs

                rawSignals = [];

                for i = 1:numel(DB.Files)

                    if abs(DB.Files(i).Ball.Diameter_mm - D_target) > 1e-9
                        continue;
                    end

                    if ss > numel(DB.Files(i).Sensors)
                        continue;
                    end

                    sig = DB.Files(i).Sensors(ss).signal0;
                    if isempty(sig); continue; end

                    sig = sig(:)';
                    rawSignals = app.alignAndAppend(rawSignals, sig);

                    if showRaw
                        t_src_us = app.getSourceTime_us(ss, numel(sig), sig);
                        if isnan(t_src_us)
                            triggerID = app.getTriggerSampleIndex(numel(sig));
                            t_src_us = (triggerID-1) / Fs * 1e6;
                        end

                        t_us = (0:numel(sig)-1) / Fs * 1e6 - t_src_us;

                        k = numel(app.PlotData.ExpRaw) + 1;
                        app.PlotData.ExpRaw(k).t = t_us;
                        app.PlotData.ExpRaw(k).y = sig;
                    end
                end

                if isempty(rawSignals)
                    continue;
                end

                avgSig = mean(rawSignals,1,'omitnan');

                t_src_us = app.getSourceTime_us(ss, numel(avgSig), avgSig);
                if isnan(t_src_us)
                    triggerID = app.getTriggerSampleIndex(numel(avgSig));
                    t_src_us = (triggerID-1) / Fs * 1e6;
                end

                t_avg_us = (0:numel(avgSig)-1) / Fs * 1e6 - t_src_us;

                k = numel(app.PlotData.ExpAvg) + 1;
                app.PlotData.ExpAvg(k).t = t_avg_us;
                app.PlotData.ExpAvg(k).y = avgSig;

                if app.ShowTheoryCheckBox.Value
                    [theory_nm, t_theory_us] = app.computeBallTheoreticalWaveformByMethod( ...
                        ss, D_target, numel(avgSig), "NM");

                    if ~isempty(theory_nm)
                        k = numel(app.PlotData.Theory) + 1;
                        app.PlotData.Theory(k).t = t_theory_us;
                        app.PlotData.Theory(k).y = theory_nm;
                    end

                    [arrTimes_us, arrLabels] = app.getRayArrivalTimes_us(ss);

                    if ~isempty(arrTimes_us)
                        k = numel(app.PlotData.Arrivals) + 1;
                        app.PlotData.Arrivals(k).SensorID = ss;
                        app.PlotData.Arrivals(k).Times_us = arrTimes_us;
                        app.PlotData.Arrivals(k).Labels = arrLabels;
                    end
                end
            end

            app.PlotData.Title = sprintf('Ball diameter = %.1f mm',D_target);
        end

        function prepareCapillaryPlotData(app)

            if ~isfield(app.WaveformDB,'Capillary')
                uialert(app.UIFigure,'No capillary data found in WaveformDB.','Missing Data');
                return;
            end

            DB = app.WaveformDB.Capillary;
            Config = app.WaveformDB.Config;
            Fs = Config.DAQ.Fs;

            selectedSensorIDs = app.getSelectedSensorIDs();
            isSingleSensor = strcmp(app.SensorModeDropDown.Value,'Single sensor');
            showRaw = app.ShowRawCheckBox.Value && isSingleSensor;

            % Collect capillary source force signals once, independent of sensor
            forceSignalsAll = [];

            for i = 1:numel(DB.Files)
                if isfield(DB.Files(i),'signal_source') && ~isempty(DB.Files(i).signal_source)
                    forceSig = DB.Files(i).signal_source(:)';
                    forceSignalsAll = app.alignAndAppend(forceSignalsAll,forceSig);
                end
            end

            for ss = selectedSensorIDs

                rawSignals = [];

                for i = 1:numel(DB.Files)

                    if ss > numel(DB.Files(i).Sensors)
                        continue;
                    end

                    sig = DB.Files(i).Sensors(ss).signal0;
                    if isempty(sig); continue; end

                    sig = sig(:)';
                    rawSignals = app.alignAndAppend(rawSignals, sig);

                    % Raw voltage, source-time aligned
                    if showRaw
                        t_src_us = app.getSourceTime_us(ss,numel(sig),sig);
                        if isnan(t_src_us)
                            triggerID = app.getTriggerSampleIndex(numel(sig));
                            t_src_us = (triggerID-1) / Fs * 1e6;
                        end

                        t_us = (0:numel(sig)-1) / Fs * 1e6 - t_src_us;

                        k = numel(app.PlotData.ExpRaw) + 1;
                        app.PlotData.ExpRaw(k).t = t_us;
                        app.PlotData.ExpRaw(k).y = sig;
                    end
                end

                if isempty(rawSignals)
                    continue;
                end

                % Averaged voltage, source-time aligned
                avgSig = mean(rawSignals,1,'omitnan');

                t_src_us = app.getSourceTime_us(ss,numel(avgSig),avgSig);
                if isnan(t_src_us)
                    triggerID = app.getTriggerSampleIndex(numel(avgSig));
                    t_src_us = (triggerID-1) / Fs * 1e6;
                end

                t_avg_us = (0:numel(avgSig)-1) / Fs * 1e6 - t_src_us;

                k = numel(app.PlotData.ExpAvg) + 1;
                app.PlotData.ExpAvg(k).t = t_avg_us;
                app.PlotData.ExpAvg(k).y = avgSig;

                % Capillary theoretical waveform
                if app.ShowTheoryCheckBox.Value && ~isempty(forceSignalsAll)

                    avgForceVoltage = mean(forceSignalsAll,1,'omitnan');

                    [theory_nm, t_theory_us] = app.computeCapillaryTheoreticalWaveform( ...
                        ss, avgSig, avgForceVoltage);

                    if ~isempty(theory_nm)
                        k = numel(app.PlotData.Theory) + 1;
                        app.PlotData.Theory(k).t = t_theory_us;
                        app.PlotData.Theory(k).y = theory_nm;
                    end
                end

                % Ray arrivals for capillary fracture too
                [arrTimes_us, arrLabels] = app.getRayArrivalTimes_us(ss);

                if ~isempty(arrTimes_us)
                    k = numel(app.PlotData.Arrivals) + 1;
                    app.PlotData.Arrivals(k).SensorID = ss;
                    app.PlotData.Arrivals(k).Times_us = arrTimes_us;
                    app.PlotData.Arrivals(k).Labels = arrLabels;
                end
            end

            app.PlotData.Title = 'Capillary fracture';

        end

        function refreshVisiblePlot(app)

            yyaxis(app.UIAxes,'left');
            cla(app.UIAxes);
            ylim(app.UIAxes,'auto');
            hold(app.UIAxes,'on');

            for k = 1:numel(app.PlotData.ExpRaw)
                t = app.PlotData.ExpRaw(k).t;
                y = app.PlotData.ExpRaw(k).y;
                id = t >= app.ViewXLim(1) & t <= app.ViewXLim(2);

                if any(id)
                    step = max(1,round(nnz(id)/3000));
                    tt = t(id);
                    yy = y(id);

                    plot(app.UIAxes,tt(1:step:end),yy(1:step:end), ...
                        'Color',[0.78 0.78 0.78], ...
                        'LineStyle','-', ...
                        'Marker','none', ...
                        'LineWidth',0.25);
                end
            end

            for k = 1:numel(app.PlotData.ExpAvg)
                t = app.PlotData.ExpAvg(k).t;
                y = app.PlotData.ExpAvg(k).y;
                id = t >= app.ViewXLim(1) & t <= app.ViewXLim(2);
                if ~isempty(app.ViewYLimLeft)
                    id = id & y >= app.ViewYLimLeft(1) & y <= app.ViewYLimLeft(2);
                end

                if any(id)
                    plot(app.UIAxes,t(id),y(id), ...
                        'Color',[0 0 0], ...
                        'LineStyle','-', ...
                        'Marker','none', ...
                        'LineWidth',1.2);
                end
            end

            ylabel(app.UIAxes,'Experimental voltage (V)');
            app.UIAxes.YColor = [0 0 0];

            yyaxis(app.UIAxes,'right');
            cla(app.UIAxes);
            ylim(app.UIAxes,'auto');
            hold(app.UIAxes,'on');

            for k = 1:numel(app.PlotData.Theory)
                t = app.PlotData.Theory(k).t;
                y = app.PlotData.Theory(k).y;
                id = t >= app.ViewXLim(1) & t <= app.ViewXLim(2);
                if ~isempty(app.ViewYLimRight)
                    id = id & y >= app.ViewYLimRight(1) & y <= app.ViewYLimRight(2);
                end

                if any(id)
                    plot(app.UIAxes,t(id),y(id), ...
                        'Color',[1 0 0], ...
                        'LineStyle','-', ...
                        'Marker','none', ...
                        'LineWidth',1.2);
                end
            end

            ylabel(app.UIAxes,'Theoretical displacement (nm)');
            app.UIAxes.YColor = [1 0 0];

            yyaxis(app.UIAxes,'left');
            xlim(app.UIAxes,app.ViewXLim);

            xlabel(app.UIAxes,'Time relative to source (μs)');
            title(app.UIAxes,app.PlotData.Title);

            app.UIAxes.Box = 'on';
            app.UIAxes.LineWidth = 1.2;
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';

            if app.ResetYOnRefresh
                app.matchZeroYAxis();
                app.ResetYOnRefresh = false;
            end
            app.plotArrivalMarkersFromPlotData();
        end

        function [theory_nm, t_theory_rel_us, TheoryInfo] = computeBallTheoreticalWaveformByMethod(app, sensorID, D_target, N_meas, method)
            [theory_nm,t_theory_rel_us,TheoryInfo] = ...
                calibwave.physics.computeBallTheoreticalWaveform( ...
                app.WaveformDB.Config,sensorID,D_target,N_meas,method);
        end

        function t_src_us = getSourceTime_us(app, sensorID, N_meas, sig)
            t_src_us = calibwave.signal.getSourceTime( ...
                app.WaveformDB.Config,sensorID,N_meas,sig);
        end

        function [arrTimes_us, arrLabels] = getRayArrivalTimes_us(app,sensorID)
            [arrTimes_us,arrLabels] = calibwave.physics.getRayArrivalTimes( ...
                app.WaveformDB.Config,sensorID);
        end

        function [G, t_G, id, tP, RAY] = getGreenFunctionByOffset(app, GF, r_now, method)
            if nargin < 4, method = "Ray"; end
            [G,t_G,id,tP,RAY] = calibwave.physics.getGreenFunctionByOffset( ...
                GF,r_now,method);
        end

        function [source, SourceInfo] = makeBallDropSourceFunction(app, ball, id, Fs, N, specimen)
            if nargin < 6, specimen = []; end
            [source,SourceInfo] = calibwave.physics.makeBallDropSourceFunction( ...
                ball,id,Fs,N,specimen);
        end

        function plotArrivalMarkersFromPlotData(app)

            if ~isfield(app.PlotData,'Arrivals') || isempty(app.PlotData.Arrivals)
                return;
            end

            yyaxis(app.UIAxes,'left');
            yl = ylim(app.UIAxes);
            yTop = yl(2);
            yRange = diff(yl);

            for k = 1:numel(app.PlotData.Arrivals)

                times = app.PlotData.Arrivals(k).Times_us;
                labels = app.PlotData.Arrivals(k).Labels;

                for i = 1:numel(times)

                    x = times(i);

                    if isnan(x) || x < app.ViewXLim(1) || x > app.ViewXLim(2)
                        continue;
                    end

                    xline(app.UIAxes,x,'--b','LineWidth',0.8);

                    yText = yTop - (0.08 + 0.06*mod(i-1,3))*yRange;

                    text(app.UIAxes,x,yText,labels(i), ...
                        'Tag','ArrivalLabel', ...
                        'Color','b', ...
                        'FontWeight','bold', ...
                        'FontSize',12, ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','top', ...
                        'Clipping','on');
                end
            end
        end

        function matchZeroYAxis(app)

            yyaxis(app.UIAxes,'left');
            yl = ylim(app.UIAxes);
            maxL = max(abs(yl));
            if maxL == 0 || ~isfinite(maxL); maxL = 1; end
            ylim(app.UIAxes,[-maxL maxL]);

            yyaxis(app.UIAxes,'right');
            yr = ylim(app.UIAxes);
            maxR = max(abs(yr));
            if maxR == 0 || ~isfinite(maxR); maxR = 1; end
            ylim(app.UIAxes,[-maxR maxR]);

            yyaxis(app.UIAxes,'left');
        end

        function setZoomMode(app,mode)

            app.ZoomMode = mode;

            app.ZoomXButton.FontWeight = 'normal';
            app.ZoomYButton.FontWeight = 'normal';
            app.PanButton.FontWeight = 'normal';

            switch mode
                case "X"
                    app.ZoomXButton.FontWeight = 'bold';
                case "Y"
                    app.ZoomYButton.FontWeight = 'bold';
                case "Pan"
                    app.PanButton.FontWeight = 'bold';
            end
        end

        function mouseWheelZoom(app,event)

            if isempty(app.PlotData)
                return;
            end

            zoomFactor = 1.15;

            if event.VerticalScrollCount < 0
                scale = 1/zoomFactor;
            else
                scale = zoomFactor;
            end

            if app.ZoomMode == "X"

                xc = mean(app.ViewXLim);
                xr = diff(app.ViewXLim)/2 * scale;

                app.ViewXLim = [xc-xr xc+xr];
                app.ResetYOnRefresh = false;
                app.refreshVisiblePlot();

            elseif app.ZoomMode == "Y"

                yyaxis(app.UIAxes,'left');
                yl = ylim(app.UIAxes);
                yc = mean(yl);
                yr = diff(yl)/2 * scale;
                app.ViewYLimLeft = [yc-yr yc+yr];

                yyaxis(app.UIAxes,'right');
                yr0 = ylim(app.UIAxes);
                yc0 = mean(yr0);
                yr1 = diff(yr0)/2 * scale;
                app.ViewYLimRight = [yc0-yr1 yc0+yr1];

                app.ResetYOnRefresh = false;
                app.refreshVisiblePlot();

                yyaxis(app.UIAxes,'left');
                ylim(app.UIAxes,app.ViewYLimLeft);

                yyaxis(app.UIAxes,'right');
                ylim(app.UIAxes,app.ViewYLimRight);

                yyaxis(app.UIAxes,'left');
            end
        end

        function startPan(app)

            if app.ZoomMode ~= "Pan" || isempty(app.PlotData)
                return;
            end

            app.IsPanning = true;
            cp = app.UIAxes.CurrentPoint;
            app.PanStartPoint = cp(1,1);
            app.PanStartXLim = app.ViewXLim;
        end

        function doPan(app)

            if ~app.IsPanning || app.ZoomMode ~= "Pan"
                return;
            end

            cp = app.UIAxes.CurrentPoint;
            xNow = cp(1,1);

            dx = xNow - app.PanStartPoint;

            app.ViewXLim = app.PanStartXLim - dx;
            app.ResetYOnRefresh = false;
            app.refreshVisiblePlot();
        end

        function stopPan(app)
            app.IsPanning = false;
        end

        function ids = getSelectedSensorIDs(app)

            items = string(app.SensorListBox.Items);
            selected = string(app.SensorListBox.Value);

            ids = [];
            for i = 1:numel(selected)
                tmp = find(items == selected(i),1);
                if ~isempty(tmp)
                    ids(end+1) = tmp; %#ok<AGROW>
                end
            end

            if isempty(ids)
                ids = 1;
            end

            if strcmp(app.SensorModeDropDown.Value,'Single sensor')
                ids = ids(1);
            end
        end

        function X = alignAndAppend(app, X, sig)
            X = calibwave.signal.alignAndAppend(X,sig);
        end

        function idPick = pickArrivalAIC(app, sig, centerID, halfWin)
            idPick = calibwave.signal.pickArrivalAIC(sig,centerID,halfWin);
        end

        function [theory_nm,t_theory_us] = computeCapillaryTheoreticalWaveform(app,sensorID,signal_w,signal_source)
            [theory_nm,t_theory_us] = ...
                calibwave.physics.computeCapillaryTheoreticalWaveform( ...
                app.WaveformDB.Config,sensorID,signal_w,signal_source);
        end

        function Force = makeCapillaryForceFunction(~,cap,signal_w,signal_source,DAQ)
            Force = calibwave.physics.makeCapillaryForceFunction( ...
                cap,signal_w,signal_source,DAQ);
        end
        function openFFTViewer(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.PlotData)
                uialert(app.UIFigure,...
                    'Please plot waveform first.',...
                    'No Data');
                return;
            end

            FFTConfig.DAQ.Fs = app.WaveformDB.Config.DAQ.Fs;

            app.FFTApp = FFTViewer( ...
                app.PlotData,...
                FFTConfig,...
                app);
            restoreFocus = [];
            calibwave.ui.bringToFront(app.FFTApp.UIFigure);

        end

        function FFTPlotData = prepareFFTPlotData(app,fmin_kHz)

            FFTPlotData = app.PlotData;

            titleText = lower(string(app.PlotData.Title));

            isCapillary = contains(titleText,'capillary');

            if isCapillary
                method = "Ray";
            else
                if fmin_kHz >= 100
                    method = "Ray";
                else
                    method = "NM";
                end
            end

            FFTPlotData.Theory = struct([]);

            if contains(titleText,'ball diameter')
                D_target = str2double(app.BallSizeDropDown.Value);
                selectedSensorIDs = app.getSelectedSensorIDs();

                for ss = selectedSensorIDs

                    N_meas = numel(app.PlotData.ExpAvg(1).y);

                    [theory_nm,t_theory_us] = app.computeBallTheoreticalWaveformByMethod( ...
                        ss,D_target,N_meas,method);

                    if ~isempty(theory_nm)
                        k = numel(FFTPlotData.Theory) + 1;
                        FFTPlotData.Theory(k).t = t_theory_us;
                        FFTPlotData.Theory(k).y = theory_nm;
                    end
                end

                FFTPlotData.Title = sprintf('%s, theory = %s GF', ...
                    string(app.PlotData.Title), method);

            elseif isCapillary

                FFTPlotData = app.PlotData;
                FFTPlotData.Title = 'Capillary fracture, theory = Ray GF';
                return;
            end
        end

        function closeFFTViewer(app)

            if isempty(app.FFTApp)
                return;
            end

            try
                if isvalid(app.FFTApp)
                    delete(app.FFTApp.UIFigure);
                end
            catch
            end

            app.FFTApp = [];
        end

        function exportCurrentWaveformFigure(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.PlotData)
                uialert(app.UIFigure,'Please plot waveform first.','No Data');
                return;
            end

            fileType = app.ExportTypeDropDown.Value;
            folder = app.getSelectedSensorExportFolder();

            if ~exist(folder,'dir')
                mkdir(folder);
            end

            titleText = calibwave.io.sanitizeFileStem(app.PlotData.Title);

            fileBase = fullfile(folder,"Waveform_" + titleText);

            app.exportAxesWithExportFig(fileBase,fileType);
            app.exportCurrentZoomData(fileBase);
            app.exportCurrentFFTFigure();
        end

        function exportCurrentZoomData(app,fileBase)
            visibleXLim_us = xlim(app.UIAxes);
            ZoomData = calibwave.io.cropPlotDataToTimeWindow( ...
                app.PlotData,visibleXLim_us);

            ZoomData.Metadata.ExportedAt = datetime("now");
            ZoomData.Metadata.Source = "WaveformViewer.ExportCurrent";
            ZoomData.Metadata.GroupMode = string(app.GroupModeDropDown.Value);
            ZoomData.Metadata.SensorMode = string(app.SensorModeDropDown.Value);
            ZoomData.Metadata.SelectedSensorIDs = app.getSelectedSensorIDs();
            ZoomData.Metadata.SelectedSensorLabels = ...
                string(app.SensorListBox.Value);
            ZoomData.Metadata.ShowTheory = app.ShowTheoryCheckBox.Value;
            ZoomData.Metadata.ShowRawRepeats = app.ShowRawCheckBox.Value;
            if strcmp(app.GroupModeDropDown.Value,'Ball size')
                ZoomData.Metadata.BallSize_mm = ...
                    str2double(app.BallSizeDropDown.Value);
            else
                ZoomData.Metadata.BallSize_mm = NaN;
            end

            save(char(string(fileBase) + "_ZoomData.mat"),'ZoomData');
        end

        function exportAxesWithExportFig(app,fileBase,fileType)
            calibwave.plotting.exportAxes(app.UIAxes,fileBase,fileType);
        end

        function folder = getSelectedSensorExportFolder(app)

            ids = app.getSelectedSensorIDs();
            ss = ids(1);

            SensorArray = app.WaveformDB.Config.SensorArray;

            sensorLabel = string(SensorArray(ss).SensorLabel);
            sensorLabel = regexprep(sensorLabel,'[^\w\d\-]','_');

            rootFolder = fullfile(pwd,'ExportedFigures');

            folder = fullfile(rootFolder,sensorLabel);
        end

        function exportAllWaveformFigures(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.WaveformDB)
                uialert(app.UIFigure,'Please load WaveformDB first.','No Data');
                return;
            end

            oldGroup = app.GroupModeDropDown.Value;
            oldBall = app.BallSizeDropDown.Value;
            oldSensorValue = app.SensorListBox.Value;

            selectedSensors = string(app.SensorListBox.Value);
            ballItems = string(app.BallSizeDropDown.Items);

            for i = 1:numel(selectedSensors)

                app.SensorListBox.Value = selectedSensors(i);

                app.GroupModeDropDown.Value = 'Ball size';

                for j = 1:numel(ballItems)

                    app.BallSizeDropDown.Value = ballItems(j);

                    app.plotWaveforms();
                    drawnow;

                    app.exportCurrentWaveformFigure();
                end

                app.GroupModeDropDown.Value = 'Capillary fracture';

                app.plotWaveforms();
                drawnow;

                app.exportCurrentWaveformFigure();
                % Export final sensor sensitivity lower-panel plot and data
                app.exportCurrentSensorSensitivity();
            end

            app.GroupModeDropDown.Value = oldGroup;
            app.BallSizeDropDown.Value = oldBall;
            app.SensorListBox.Value = oldSensorValue;

            app.plotWaveforms();
        end

        function exportCurrentFFTFigure(app)

            if isempty(app.PlotData)
                return;
            end

            fileType = app.ExportTypeDropDown.Value;
            folder = app.getSelectedSensorExportFolder();

            if ~exist(folder,'dir')
                mkdir(folder);
            end

            titleText = calibwave.io.sanitizeFileStem(app.PlotData.Title);

            fileBase = fullfile(folder,"FFT_" + titleText);

            FFTConfig.DAQ.Fs = app.WaveformDB.Config.DAQ.Fs;

            fftApp = FFTViewer(app.PlotData,FFTConfig,app);
            drawnow;

            fftApp.exportAxesOnly(fileBase,fileType);

            delete(fftApp.UIFigure);
        end

        function triggerID = getTriggerSampleIndex(app,N)
            triggerID = calibwave.signal.getTriggerSampleIndex( ...
                N,app.WaveformDB.Config.DAQ);
        end

        function exportCurrentSensorSensitivity(app)

            if isempty(app.PlotData)
                return;
            end

            fileType = app.ExportTypeDropDown.Value;
            folder = app.getSelectedSensorExportFolder();

            if ~exist(folder,'dir')
                mkdir(folder);
            end

            FFTConfig.DAQ.Fs = app.WaveformDB.Config.DAQ.Fs;

            fftApp = FFTViewer(app.PlotData,FFTConfig,app);
            drawnow;

            SensData = fftApp.computeSensorSensitivityFromAllSources();

            if isempty(SensData) || ~isfield(SensData,'S_final')
                delete(fftApp.UIFigure);
                return;
            end

            fileBase = fullfile(folder,"SensorSensitivity_Final");

            % Save MAT
            save(char(fileBase + ".mat"),'SensData');

            % Save CSV
            T = table( ...
                SensData.freqCommon(:), ...
                SensData.freqCommon(:)/1e3, ...
                SensData.S_final(:), ...
                'VariableNames',{'Frequency_Hz','Frequency_kHz', ...
                'Sensitivity_V_per_nm'});

            writetable(T,char(fileBase + ".csv"));

            % Export lower-panel figure only
            sensApp = SensorSensitivityViewer(SensData);
            drawnow;

            sensApp.exportLowerPanelOnly(fileBase,fileType);

            delete(sensApp.UIFigure);
            delete(fftApp.UIFigure);
        end
    end
end
