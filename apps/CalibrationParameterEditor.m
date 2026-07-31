classdef CalibrationParameterEditor < matlab.apps.AppBase

    properties
        UIFigure

        BallPanel
        CapPanel
        DAQPanel
        FilePanel

        BallRhoEditField
        BallYoungEditField
        BallNuEditField
        BallDiameterEditField
        BallDropHeightEditField

        CapFVSenEditField
        CapTauRiseEditField
        CapT2EditField
        CapForceChannelEditField

        DAQFsEditField
        DAQFminModelEditField
        DAQFmaxModelEditField
        DAQFminRayEditField
        DAQFmaxRayEditField
        DAQPreTriggerRatioEditField

        SensorMapPathEditField
        GFPathEditField
        AmpCalPathEditField

        LoadSensorMapButton
        LoadGFButton
        LoadAmpCalButton
        SaveConfigButton

        SensorGrid
        SensorArray
        GF
        AmpCalibration_Elsys
        CalibConfig
    end

    methods

        function app = CalibrationParameterEditor
            createComponents(app);
        end

        function createComponents(app)

            app.UIFigure = uifigure('Name','Calibration Parameter Editor');
            app.UIFigure.Position = [100 100 900 560];
            %% Steel ball panel
            app.BallPanel = uipanel(app.UIFigure, ...
                'Title','Steel Ball Parameters', ...
                'Position',[30 340 400 190]);

            xLabel = 25;
            xEdit  = 190;
            wLabel = 150;
            wEdit  = 170;
            hEdit  = 24;

            y0 = 130;
            dy = 32;

            uilabel(app.BallPanel,'Text','Density rho (kg/m3)', ...
                'Position',[xLabel y0 wLabel 22]);
            app.BallRhoEditField = uieditfield(app.BallPanel,'numeric', ...
                'Position',[xEdit y0 wEdit hEdit],'Value',7850);

            uilabel(app.BallPanel,'Text','Young''s modulus (GPa)', ...
                'Position',[xLabel y0-dy wLabel 22]);
            app.BallYoungEditField = uieditfield(app.BallPanel,'numeric', ...
                'Position',[xEdit y0-dy wEdit hEdit],'Value',210);

            uilabel(app.BallPanel,'Text','Poisson ratio', ...
                'Position',[xLabel y0-2*dy wLabel 22]);
            app.BallNuEditField = uieditfield(app.BallPanel,'numeric', ...
                'Position',[xEdit y0-2*dy wEdit hEdit],'Value',0.283);

            uilabel(app.BallPanel,'Text','Ball diameters (mm)', ...
                'Position',[xLabel y0-3*dy wLabel 22]);
            app.BallDiameterEditField = uieditfield(app.BallPanel,'text', ...
                'Position',[xEdit y0-3*dy wEdit hEdit], ...
                'Value','0.5,0.7,1,1.5,2,3');

            uilabel(app.BallPanel,'Text','Drop height (mm)', ...
                'Position',[xLabel y0-4*dy wLabel 22]);
            app.BallDropHeightEditField = uieditfield(app.BallPanel,'numeric', ...
                'Position',[xEdit y0-4*dy wEdit hEdit],'Value',200);


            %% Capillary fracture panel
            app.CapPanel = uipanel(app.UIFigure, ...
                'Title','Capillary Fracture Parameters', ...
                'Position',[470 340 400 190]);

            xLabel = 25;
            xEdit  = 210;
            wLabel = 170;
            wEdit  = 130;
            hEdit  = 24;

            y0 = 130;
            dy = 34;

            uilabel(app.CapPanel,'Text','Force sensor sen. (V/N)', ...
                'Position',[xLabel y0 wLabel 22]);
            app.CapFVSenEditField = uieditfield(app.CapPanel,'numeric', ...
                'Position',[xEdit y0 wEdit hEdit],'Value',0.852/4.44);

            uilabel(app.CapPanel,'Text','Rise time τ (μs)', ...
                'Position',[xLabel y0-dy wLabel 22]);
            app.CapTauRiseEditField = uieditfield(app.CapPanel,'numeric', ...
                'Position',[xEdit y0-dy wEdit hEdit],'Value',0.1);

            uilabel(app.CapPanel,'Text','T2 cf (μs)', ...
                'Position',[xLabel y0-2*dy wLabel 22]);
            app.CapT2EditField = uieditfield(app.CapPanel,'numeric', ...
                'Position',[xEdit y0-2*dy wEdit hEdit],'Value',40);

            uilabel(app.CapPanel,'Text','Force channel', ...
                'Position',[xLabel y0-3*dy wLabel 22]);
            app.CapForceChannelEditField = uieditfield(app.CapPanel,'text', ...
                'Position',[xEdit y0-3*dy wEdit hEdit],'Value','F1');


            %% DAQ panel
            app.DAQPanel = uipanel(app.UIFigure, ...
                'Title','DAQ and Frequency Settings', ...
                'Position',[30 100 400 220]);

            xLabel = 25;
            xEdit1 = 210;
            xEdit2 = 300;
            wLabel = 170;
            wEdit  = 80;
            hEdit  = 24;

            y0 = 155;
            dy = 42;

            uilabel(app.DAQPanel,'Text','Sampling rate Fs (MHz)', ...
                'Position',[xLabel y0 wLabel 22]);
            app.DAQFsEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit1 y0 120 hEdit],'Value',10);

            uilabel(app.DAQPanel,'Text','Pre-trigger ratio', ...
                'Position',[xLabel y0-dy wLabel 22]);
            app.DAQPreTriggerRatioEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit1 y0-dy 120 hEdit], ...
                'Value',0.5, ...
                'Limits',[0 1]);

            uilabel(app.DAQPanel,'Text','Modeling band (kHz)', ...
                'Position',[xLabel y0-2*dy wLabel 22]);
            app.DAQFminModelEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit1 y0-2*dy wEdit hEdit],'Value',1);
            app.DAQFmaxModelEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit2 y0-2*dy wEdit hEdit],'Value',2500);

            uilabel(app.DAQPanel,'Text','Ray theory band (kHz)', ...
                'Position',[xLabel y0-3*dy wLabel 22]);
            app.DAQFminRayEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit1 y0-3*dy wEdit hEdit],'Value',100);
            app.DAQFmaxRayEditField = uieditfield(app.DAQPanel,'numeric', ...
                'Position',[xEdit2 y0-3*dy wEdit hEdit],'Value',2500);


            %% File panel
            app.FilePanel = uipanel(app.UIFigure, ...
                'Title','Input Files', ...
                'Position',[470 100 400 220]);

            xLabel = 25;
            xEdit  = 140;
            xBtn   = 315;
            wLabel = 105;
            wEdit  = 165;
            wBtn   = 70;
            hEdit  = 24;

            y0 = 140;
            dy = 42;

            uilabel(app.FilePanel,'Text','SensorMap.mat', ...
                'Position',[xLabel y0 wLabel 22]);
            app.SensorMapPathEditField = uieditfield(app.FilePanel,'text', ...
                'Position',[xEdit y0 wEdit hEdit]);
            app.LoadSensorMapButton = uibutton(app.FilePanel,'push', ...
                'Text','Browse', ...
                'Position',[xBtn y0 wBtn hEdit], ...
                'ButtonPushedFcn',@(src,event) loadSensorMap(app));

            uilabel(app.FilePanel,'Text','GF.mat', ...
                'Position',[xLabel y0-dy wLabel 22]);
            app.GFPathEditField = uieditfield(app.FilePanel,'text', ...
                'Position',[xEdit y0-dy wEdit hEdit]);
            app.LoadGFButton = uibutton(app.FilePanel,'push', ...
                'Text','Browse', ...
                'Position',[xBtn y0-dy wBtn hEdit], ...
                'ButtonPushedFcn',@(src,event) loadGF(app));

            uilabel(app.FilePanel,'Text','AmpCal.mat', ...
                'Position',[xLabel y0-2*dy wLabel 22]);
            app.AmpCalPathEditField = uieditfield(app.FilePanel,'text', ...
                'Position',[xEdit y0-2*dy wEdit hEdit]);
            app.LoadAmpCalButton = uibutton(app.FilePanel,'push', ...
                'Text','Browse', ...
                'Position',[xBtn y0-2*dy wBtn hEdit], ...
                'ButtonPushedFcn',@(src,event) loadAmpCal(app));


            %% Save button
            app.SaveConfigButton = uibutton(app.UIFigure,'push', ...
                'Text','Save CalibConfig', ...
                'FontWeight','bold', ...
                'Position',[360 35 180 36], ...
                'ButtonPushedFcn',@(src,event) saveCalibConfig(app));

        end

        function loadSensorMap(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load SensorMap.mat');
            if isequal(file,0); return; end

            fullpath = fullfile(path,file);
            try
                [app.SensorGrid,app.SensorArray] = ...
                    calibwave.io.loadSensorMap(fullpath);
            catch ex
                uialert(app.UIFigure,ex.message,'Load Error');
                return;
            end

            app.SensorMapPathEditField.Value = fullpath;
        end

        function loadGF(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load GF.mat');
            if isequal(file,0); return; end

            fullpath = fullfile(path,file);
            data = load(fullpath);

            app.GF = data;
            app.GFPathEditField.Value = fullpath;
        end

        function loadAmpCal(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load AmpCalibration_Elsys.mat');
            if isequal(file,0); return; end

            fullpath = fullfile(path,file);
            data = load(fullpath);

            if isfield(data,'AmpCalibration_Elsys')
                app.AmpCalibration_Elsys = data.AmpCalibration_Elsys;
            else
                app.AmpCalibration_Elsys = data;
            end

            app.AmpCalPathEditField.Value = fullpath;
        end

        function CalibConfig = collectCalibConfig(app)
            input.ball.rho = app.BallRhoEditField.Value;
            input.ball.young = app.BallYoungEditField.Value * 1e9;
            input.ball.nu = app.BallNuEditField.Value;

            D_mm = str2num(app.BallDiameterEditField.Value); %#ok<ST2NM>
            input.ball.D = D_mm(:) / 1e3;
            input.ball.R = input.ball.D / 2;
            dropHeight = app.BallDropHeightEditField.Value * 1e-3;
            input.ball.h = dropHeight - input.ball.R;

            input.cap.FV_Sen = app.CapFVSenEditField.Value;
            input.cap.tau_rise = app.CapTauRiseEditField.Value * 1e-6;
            input.cap.T2_cf = app.CapT2EditField.Value;
            input.cap.chanName_Force = string(app.CapForceChannelEditField.Value);

            input.DAQ.Fs = app.DAQFsEditField.Value * 1e6;
            input.DAQ.PreTriggerRatio = app.DAQPreTriggerRatioEditField.Value;
            input.DAQ.fmin_Model = app.DAQFminModelEditField.Value * 1e3;
            input.DAQ.fmax_Model = app.DAQFmaxModelEditField.Value * 1e3;
            input.DAQ.fmin_Ray = app.DAQFminRayEditField.Value * 1e3;
            input.DAQ.fmax_Ray = app.DAQFmaxRayEditField.Value * 1e3;
            input.DAQ.SensorMapPath = string(app.SensorMapPathEditField.Value);
            input.DAQ.GFPath = string(app.GFPathEditField.Value);
            input.DAQ.AmpCalPath = string(app.AmpCalPathEditField.Value);
            input.DAQ.AmpCalibration_Elsys = app.AmpCalibration_Elsys;

            input.GF = app.GF;
            input.SensorArray = app.SensorArray;
            input.SensorGrid = app.SensorGrid;
            CalibConfig = calibwave.config.buildCalibConfig(input);

        end

        function saveCalibConfig(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.SensorArray)
                uialert(app.UIFigure, ...
                    'Please load SensorMap.mat before saving CalibConfig.', ...
                    'Missing Sensor Map');
                return;
            end

            CalibConfig = collectCalibConfig(app);
            app.CalibConfig = CalibConfig;

            [file,path] = uiputfile('CalibConfig.mat','Save Calibration Config');
            if isequal(file,0); return; end

            calibwave.io.saveCalibrationConfig(fullfile(path,file),CalibConfig);

            uialert(app.UIFigure, ...
                sprintf('Saved CalibConfig with %d active sensors.', ...
                numel(CalibConfig.SensorArray)), ...
                'Saved');
        end
    end
end
