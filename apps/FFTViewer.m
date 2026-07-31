classdef FFTViewer < matlab.apps.AppBase

    properties
        UIFigure
        UIAxes

        SignalDropDown
        PlotButton
        FminEditField
        FmaxEditField

        PlotData
        Config
        ParentApp

        NoiseRatioThreshold = 3
        ValidFreqLow_kHz = NaN
        ValidFreqHigh_kHz = NaN
        LastFcVoltage_kHz = NaN
        LastFcTheory_kHz = NaN
        LastSensitivityMean = NaN
        LastSensitivityStd = NaN
        LastSensitivityN = 0
        SensitivityButton
    end

    methods

        function app = FFTViewer(PlotData,Config,ParentApp)

            app.PlotData = PlotData;
            app.Config = Config;
            app.ParentApp = ParentApp;

            createComponents(app);
            initializeFrequencyRange(app);
            updateAndPlotFFT(app);
        end

        function createComponents(app)

            app.UIFigure = uifigure('Name','FFT Viewer');
            app.UIFigure.Position = [200 150 980 560];

            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [70 80 850 390];
            box(app.UIAxes,'on');
            grid(app.UIAxes,'off');
            app.UIAxes.LineWidth = 1.2;

            uilabel(app.UIFigure, ...
                'Text','Signal', ...
                'Position',[50 500 50 22]);

            app.SignalDropDown = uidropdown(app.UIFigure, ...
                'Items',{'Voltage + Theory','Voltage only','Theory only'}, ...
                'Value','Voltage + Theory', ...
                'Position',[100 500 145 25]);

            uilabel(app.UIFigure, ...
                'Text','f min (kHz)', ...
                'Position',[270 500 80 22]);

            app.FminEditField = uieditfield(app.UIFigure,'numeric', ...
                'Position',[350 500 75 25], ...
                'Value',1);

            uilabel(app.UIFigure, ...
                'Text','f max (kHz)', ...
                'Position',[445 500 80 22]);

            app.FmaxEditField = uieditfield(app.UIFigure,'numeric', ...
                'Position',[525 500 75 25], ...
                'Value',2500);

            app.PlotButton = uibutton(app.UIFigure,'push', ...
                'Text','Plot FFT', ...
                'FontWeight','bold', ...
                'Position',[630 498 100 30], ...
                'ButtonPushedFcn',@(src,event) updateAndPlotFFT(app));

            app.SensitivityButton = uibutton(app.UIFigure,'push', ...
                'Text','Compute Sensitivity', ...
                'FontWeight','bold', ...
                'Position',[745 498 160 30], ...
                'ButtonPushedFcn',@(src,event) computeAndPlotSensorSensitivity(app));
        end

        function initializeFrequencyRange(app)

            titleText = "";

            if isfield(app.PlotData,'Title')
                titleText = string(app.PlotData.Title);
            end

            if contains(lower(titleText),'capillary')
                app.FminEditField.Value = 100;
                app.FmaxEditField.Value = 2500;
            else
                app.FminEditField.Value = 1;
                app.FmaxEditField.Value = 2500;
            end
        end

        function plotFFT(app)

            cla(app.UIAxes);

            Fs = app.Config.DAQ.Fs;

            fmin_Hz = app.FminEditField.Value * 1e3;
            fmax_Hz = app.FmaxEditField.Value * 1e3;

            mode = app.SignalDropDown.Value;

            showVoltage = strcmp(mode,'Voltage + Theory') || strcmp(mode,'Voltage only');
            showTheory  = strcmp(mode,'Voltage + Theory') || strcmp(mode,'Theory only');

            app.ValidFreqLow_kHz = NaN;
            app.ValidFreqHigh_kHz = NaN;
            app.LastFcVoltage_kHz = NaN;
            app.LastFcTheory_kHz = NaN;

            freqVoltageAll = [];
            ampVoltageAll  = [];
            freqTheoryAll  = [];
            ampTheoryAll   = [];
            freqNoiseAll   = [];
            ampNoiseAll    = [];

            yyaxis(app.UIAxes,'left');
            cla(app.UIAxes);
            hold(app.UIAxes,'on');

            if showVoltage && isfield(app.PlotData,'ExpAvg')
                for k = 1:numel(app.PlotData.ExpAvg)

                    sig = app.getFFTSignalForVoltage(k);

                    [freq,A] = app.computeAmplitudeFFT(sig,Fs);
                    [freq,A] = app.cropSpectrum(freq,A,fmin_Hz,fmax_Hz);
                    [freq,A] = app.resampleSpectrumLog(freq,A,fmin_Hz,fmax_Hz,100);

                    if ~isempty(freq)
                        freqVoltageAll = [freqVoltageAll; freq(:)]; %#ok<AGROW>
                        ampVoltageAll  = [ampVoltageAll;  A(:)];    %#ok<AGROW>

                        loglog(app.UIAxes,freq/1e3,A, ...
                            'Color',[0 0 0], ...
                            'LineWidth',1.2);
                    end

                    noiseSig = app.getFFTSignalForNoise(k,numel(sig));
                    if ~isempty(noiseSig)
                        [freqN,AN] = app.computeAmplitudeFFT(noiseSig,Fs);
                        [freqN,AN] = app.cropSpectrum(freqN,AN,fmin_Hz,fmax_Hz);
                        [freqN,AN] = app.resampleSpectrumLog(freqN,AN,fmin_Hz,fmax_Hz,100);

                        if ~isempty(freqN)
                            freqNoiseAll = [freqNoiseAll; freqN(:)]; %#ok<AGROW>
                            ampNoiseAll  = [ampNoiseAll;  AN(:)];    %#ok<AGROW>

                            loglog(app.UIAxes,freqN/1e3,AN, ...
                                'Color',[0.55 0.55 0.55], ...
                                'LineStyle','--', ...
                                'LineWidth',1.0);
                        end
                    end
                end
            end

            ylabel(app.UIAxes,'Voltage spectrum (V/Hz)');
            app.UIAxes.YColor = [0 0 0];

            yyaxis(app.UIAxes,'right');
            cla(app.UIAxes);
            hold(app.UIAxes,'on');

            if showTheory && isfield(app.PlotData,'Theory')
                for k = 1:numel(app.PlotData.Theory)

                    sig = app.PlotData.Theory(k).y;

                    [freq,A] = app.computeAmplitudeFFT(sig,Fs);
                    [freq,A] = app.cropSpectrum(freq,A,fmin_Hz,fmax_Hz);

                    if isempty(freq); continue; end

                    freqTheoryAll = [freqTheoryAll; freq(:)]; %#ok<AGROW>
                    ampTheoryAll  = [ampTheoryAll;  A(:)];    %#ok<AGROW>

                    loglog(app.UIAxes,freq/1e3,A, ...
                        'Color',[1 0 0], ...
                        'LineWidth',1.2);
                end
            end

            ylabel(app.UIAxes,'Displacement spectrum (nm/Hz)');
            app.UIAxes.YColor = [1 0 0];
            app.UIAxes.YScale = 'log';

            yyaxis(app.UIAxes,'left');

            xlabel(app.UIAxes,'Frequency (kHz)');

            set(app.UIAxes, ...
                'XScale','log', ...
                'YScale','log', ...
                'LineWidth',1.2);

            xlim(app.UIAxes,[app.FminEditField.Value app.FmaxEditField.Value]);

            box(app.UIAxes,'on');
            grid(app.UIAxes,'off');

            isCapillary = contains(lower(string(app.PlotData.Title)),'capillary');
            if isCapillary

                app.ValidFreqLow_kHz  = app.FminEditField.Value;
                app.ValidFreqHigh_kHz = app.FmaxEditField.Value;

                app.LastFcVoltage_kHz = NaN;
                app.LastFcTheory_kHz  = NaN;

            else

                app.estimateValidFrequencyRange( ...
                    freqVoltageAll,ampVoltageAll, ...
                    freqTheoryAll,ampTheoryAll, ...
                    freqNoiseAll,ampNoiseAll);

            end
            app.estimateSensitivity(freqVoltageAll,ampVoltageAll,freqTheoryAll,ampTheoryAll);

            app.markValidFrequencyRange();

            if isfield(app.PlotData,'Title')
                title(app.UIAxes,string(app.PlotData.Title));
            else
                title(app.UIAxes,'FFT spectrum');
            end
        end



        function updateAndPlotFFT(app)

            fmin_kHz = app.FminEditField.Value;

            if ~isempty(app.ParentApp) && isvalid(app.ParentApp)
                app.PlotData = app.ParentApp.prepareFFTPlotData(fmin_kHz);
            end
            plotFFT(app);
        end

        function sig = getFFTSignalForVoltage(app,k)

            sig = app.PlotData.ExpAvg(k).y(:);

            if ~isfield(app.PlotData,'Theory') || isempty(app.PlotData.Theory)
                return;
            end

            if k > numel(app.PlotData.Theory)
                return;
            end

            t_exp = app.PlotData.ExpAvg(k).t(:);
            t_theory = app.PlotData.Theory(k).t(:);

            t1 = min(t_theory);
            t2 = max(t_theory);

            id = t_exp >= t1 & t_exp <= t2;

            if nnz(id) > 10
                sig = app.PlotData.ExpAvg(k).y(id);
            end
        end


        function noiseSig = getFFTSignalForNoise(app,k,Ntarget)

            noiseSig = [];

            if isfield(app.PlotData,'Noise') && numel(app.PlotData.Noise) >= k && ...
                    isfield(app.PlotData.Noise(k),'y') && ~isempty(app.PlotData.Noise(k).y)
                noiseSig = app.PlotData.Noise(k).y(:);
                return;
            end

            if ~isfield(app.PlotData,'ExpAvg') || k > numel(app.PlotData.ExpAvg)
                return;
            end

            if ~isfield(app.PlotData.ExpAvg(k),'t') || isempty(app.PlotData.ExpAvg(k).t)
                return;
            end

            t = app.PlotData.ExpAvg(k).t(:);
            y = app.PlotData.ExpAvg(k).y(:);

            if nargin < 3 || isempty(Ntarget) || Ntarget < 10
                Ntarget = min(2000,numel(y));
            end

            % Prefer the pre-source/pre-arrival part as the experimental noise window.
            idNoise = find(t < 0);

            if numel(idNoise) < 20
                return;
            end

            if numel(idNoise) >= Ntarget
                idNoise = idNoise(end-Ntarget+1:end);
            end

            noiseSig = y(idNoise);
        end

        function estimateValidFrequencyRange(app,freqV,AV,freqT,AT,freqN,AN)

            fcV = app.Fit_OmegaModel(freqV,AV);
            fcT = app.Fit_OmegaModel(freqT,AT);

            if isfinite(fcV)
                app.LastFcVoltage_kHz = fcV / 1e3;
            end

            if isfinite(fcT)
                app.LastFcTheory_kHz = fcT / 1e3;
            end

            fcAll = [fcV fcT];
            fcAll = fcAll(isfinite(fcAll));

            if ~isempty(fcAll)
                app.ValidFreqHigh_kHz = mean(fcAll) / 1e3;
            end

            fLow = app.findNoiseExceedFrequency(freqV,AV,freqN,AN);
            if isfinite(fLow)
                app.ValidFreqLow_kHz = fLow / 1e3;
            end
        end


        function err = omegaMisfit(~,q,freq,A,omegaFun)

            p = 10.^q;
            Afit = omegaFun(p,freq);

            id = isfinite(Afit) & Afit > 0;
            if nnz(id) < 10
                err = inf;
                return;
            end

            err = mean((log10(A(id)) - log10(Afit(id))).^2,'omitnan');
        end


        function markValidFrequencyRange(app)

            f1 = app.ValidFreqLow_kHz;
            f2 = app.ValidFreqHigh_kHz;

            if ~isfinite(f1) || ~isfinite(f2) || f2 <= f1
                return;
            end

            xl = xlim(app.UIAxes);
            if f2 < xl(1) || f1 > xl(2)
                return;
            end

            f1 = max(f1,xl(1));
            f2 = min(f2,xl(2));

            yyaxis(app.UIAxes,'left');
            yl = ylim(app.UIAxes);

            xline(app.UIAxes,f1,'--b','LineWidth',1.2);
            xline(app.UIAxes,f2,'--b','LineWidth',1.2);

            if ~all(isfinite(yl)) || yl(1) <= 0 || yl(2) <= yl(1)
                return;
            end

            if isfinite(app.LastSensitivityMean)

                labelText = sprintf([ ...
                    'Valid sensitivity range: %d–%d kHz    |    ', ...
                    'Sensitivity = %.3g V/nm'], ...
                    round(f1),round(f2),...
                    app.LastSensitivityMean);

            else

                labelText = sprintf( ...
                    'Valid sensitivity range: %d–%d kHz', ...
                    round(f1),round(f2));

            end

            xlabel(app.UIAxes,{ ...
                'Frequency (kHz)','', ...
                labelText});
        end


        function exportAxesOnly(app,fileBase,fileType)
            calibwave.plotting.exportAxes(app.UIAxes,fileBase,fileType);
        end
        function [freq,A] = computeAmplitudeFFT(app,sig,Fs)
            [freq,A] = calibwave.signal.computeAmplitudeFFT(sig,Fs);
        end

        function [freqCrop,ACrop] = cropSpectrum(app,freq,A,fmin,fmax)
            [freqCrop,ACrop] = calibwave.signal.cropSpectrum( ...
                freq,A,fmin,fmax);
        end

        function [freq_s,A_s] = resampleSpectrumLog(app,freq,A,fmin,fmax,nPerDecade)
            [freq_s,A_s] = calibwave.signal.resampleSpectrumLog( ...
                freq,A,fmin,fmax,nPerDecade);
        end

        function fc = Fit_OmegaModel(app,freq,A)
            fc = calibwave.sensitivity.fitOmegaModel(freq,A);
        end

        function fLow = findNoiseExceedFrequency(app,freqV,AV,freqN,AN)
            fLow = calibwave.sensitivity.findNoiseExceedFrequency( ...
                freqV,AV,freqN,AN,app.NoiseRatioThreshold);
        end


        function estimateSensitivity(app,freqV,AV,freqT,AT)

            app.LastSensitivityMean = NaN;
            app.LastSensitivityStd = NaN;
            app.LastSensitivityN = 0;

            f1 = app.ValidFreqLow_kHz * 1e3;
            f2 = app.ValidFreqHigh_kHz * 1e3;

            if ~isfinite(f1) || ~isfinite(f2) || f2 <= f1
                return;
            end

            summary = calibwave.sensitivity.summarizeSensitivity( ...
                freqV,AV,freqT,AT,f1,f2);
            app.LastSensitivityMean = summary.Mean;
            app.LastSensitivityStd = summary.StdFactor;
            app.LastSensitivityN = summary.N;
        end
        function computeAndPlotSensorSensitivity(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.ParentApp) || ~isvalid(app.ParentApp)
                uialert(app.UIFigure, ...
                    'Parent WaveformViewer is not available.', ...
                    'Missing App');
                return;
            end

            SensData = app.computeSensorSensitivityFromAllSources();

            if isempty(SensData)
                uialert(app.UIFigure, ...
                    'No sensitivity data calculated.', ...
                    'No Data');
                return;
            end

            sensApp = SensorSensitivityViewer(SensData);
            restoreFocus = [];
            calibwave.ui.bringToFront(sensApp.UIFigure);

        end
        function SensData = computeSensorSensitivityFromAllSources(app)

            parent = app.ParentApp;

            oldGroup = parent.GroupModeDropDown.Value;
            oldBall  = parent.BallSizeDropDown.Value;
            oldPlotData = parent.PlotData;

            SensData = struct();
            SensData.Curves = struct( ...
                'Name',{}, ...
                'freq',{}, ...
                'S',{}, ...
                'fLow',{}, ...
                'fHigh',{});

            % Common final frequency grid: 1 kHz to 1 MHz
            SensData.freqCommon = logspace(3,6,301);

            % ----- ball drops: NM GF, 1–100 kHz only -----
            parent.GroupModeDropDown.Value = 'Ball size';
            ballItems = string(parent.BallSizeDropDown.Items);

            for i = 1:numel(ballItems)

                parent.BallSizeDropDown.Value = ballItems(i);
                parent.plotWaveforms();

                PlotDataFFT = parent.prepareFFTPlotData(1);   % NM GF

                Curve = app.computeSensitivityCurveFromPlotData( ...
                    PlotDataFFT, ...
                    "Ball " + ballItems(i) + " mm NM", ...
                    true);

                if ~isempty(Curve)

                    id = Curve.freq >= 1e3 & Curve.freq <= 100e3;
                    Curve.freq = Curve.freq(id);
                    Curve.S = Curve.S(id);
                    Curve.fLow = 1e3;
                    Curve.fHigh = 100e3;

                    if numel(Curve.freq) > 5
                        SensData.Curves(end+1) = Curve; %#ok<AGROW>
                    end
                end
            end


            % ----- capillary fracture: Ray GF, 100 kHz–1 MHz only -----
            parent.GroupModeDropDown.Value = 'Capillary fracture';
            parent.plotWaveforms();

            PlotDataFFT = parent.prepareFFTPlotData(100);   % Ray GF

            Curve = app.computeSensitivityCurveFromPlotData( ...
                PlotDataFFT, ...
                "Capillary fracture Ray", ...
                false);

            if ~isempty(Curve)

                id = Curve.freq >= 100e3 & Curve.freq <= 1e6;
                Curve.freq = Curve.freq(id);
                Curve.S = Curve.S(id);
                Curve.fLow = 100e3;
                Curve.fHigh = 1e6;

                if numel(Curve.freq) > 5
                    SensData.Curves(end+1) = Curve;
                end
            end

            % Restore current GUI state
            parent.GroupModeDropDown.Value = oldGroup;
            parent.BallSizeDropDown.Value = oldBall;
            parent.PlotData = oldPlotData;
            parent.refreshVisiblePlot();

            SensData = app.robustAverageSensitivity(SensData);
        end

        function Curve = computeSensitivityCurveFromPlotData(app,PlotDataFFT,curveName,autoValidBand)
            Curve = calibwave.sensitivity.computeSensitivityCurve( ...
                PlotDataFFT,app.Config.DAQ.Fs,curveName,autoValidBand, ...
                app.NoiseRatioThreshold);
        end

        function [freqU,S] = computeSensitivityVector(app,freqV,AV,freqT,AT,fLow,fHigh)
            [freqU,S] = calibwave.sensitivity.computeSensitivityVector( ...
                freqV,AV,freqT,AT,fLow,fHigh);
        end

        function noiseSig = getNoiseFromPlotData(app,PlotDataFFT,k,Ntarget)
            if nargin < 4, Ntarget = []; end
            noiseSig = calibwave.sensitivity.getNoiseFromPlotData( ...
                PlotDataFFT,k,Ntarget);
        end

        function SensData = robustAverageSensitivity(app,SensData)
            SensData = calibwave.sensitivity.robustAverageSensitivity(SensData);
        end
    end
end
