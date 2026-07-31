classdef AECalibrationMainApp < matlab.apps.AppBase

    properties
        UIFigure

        OpenSensorEditorButton
        OpenParamEditorButton
        LoadConfigButton
        SelectBallFolderButton
        SelectCapFolderButton
        ExtractBallButton
        ExtractCapButton
        SaveWaveformDBButton
        OpenWaveformViewerButton

        ConfigPathEditField
        BallFolderEditField
        CapFolderEditField
        StatusTextArea

        CalibConfig
        WaveformDB
        WaveformViewerApp = []

    end

    methods

        function app = AECalibrationMainApp
            createComponents(app);
        end

        function createComponents(app)

            app.UIFigure = uifigure('Name','AE Sensor Calibration Main App');
            app.UIFigure.Position = [100 100 760 460];

            app.OpenSensorEditorButton = uibutton(app.UIFigure,'push', ...
                'Text','1. Open SensorArrayEditor', ...
                'Position',[40 390 220 32], ...
                'ButtonPushedFcn',@(src,event) openSensorEditor(app));

            app.OpenParamEditorButton = uibutton(app.UIFigure,'push', ...
                'Text','2. Open CalibrationParameterEditor', ...
                'Position',[290 390 260 32], ...
                'ButtonPushedFcn',@(src,event) openParamEditor(app));

            app.OpenWaveformViewerButton = uibutton(app.UIFigure,'push', ...
                'Text','3. Waveform Viewer', ...
                'Position',[570 390 140 32], ...
                'Enable','off', ...
                'ButtonPushedFcn',@(src,event) openWaveformViewer(app));

            uilabel(app.UIFigure,'Text','CalibConfig.mat', ...
                'Position',[40 335 120 22]);

            app.ConfigPathEditField = uieditfield(app.UIFigure,'text', ...
                'Position',[160 335 420 24]);

            app.LoadConfigButton = uibutton(app.UIFigure,'push', ...
                'Text','Load Config', ...
                'Position',[600 335 110 24], ...
                'ButtonPushedFcn',@(src,event) loadConfig(app));

            uilabel(app.UIFigure,'Text','Ball-drop folder', ...
                'Position',[40 290 120 22]);

            app.BallFolderEditField = uieditfield(app.UIFigure,'text', ...
                'Position',[160 290 420 24]);

            app.SelectBallFolderButton = uibutton(app.UIFigure,'push', ...
                'Text','Browse', ...
                'Position',[600 290 110 24], ...
                'ButtonPushedFcn',@(src,event) selectBallFolder(app));

            uilabel(app.UIFigure,'Text','Capillary folder', ...
                'Position',[40 250 120 22]);

            app.CapFolderEditField = uieditfield(app.UIFigure,'text', ...
                'Position',[160 250 420 24]);

            app.SelectCapFolderButton = uibutton(app.UIFigure,'push', ...
                'Text','Browse', ...
                'Position',[600 250 110 24], ...
                'ButtonPushedFcn',@(src,event) selectCapFolder(app));

            app.ExtractBallButton = uibutton(app.UIFigure,'push', ...
                'Text','Extract Ball-Drop Waveforms', ...
                'Position',[40 195 220 35], ...
                'ButtonPushedFcn',@(src,event) extractBallWaveforms(app));

            app.ExtractCapButton = uibutton(app.UIFigure,'push', ...
                'Text','Extract Capillary Waveforms', ...
                'Position',[290 195 220 35], ...
                'ButtonPushedFcn',@(src,event) extractCapWaveforms(app));

            app.SaveWaveformDBButton = uibutton(app.UIFigure,'push', ...
                'Text','Save WaveformDB', ...
                'FontWeight','bold', ...
                'Position',[540 195 170 35], ...
                'ButtonPushedFcn',@(src,event) saveWaveformDB(app));

            app.StatusTextArea = uitextarea(app.UIFigure, ...
                'Position',[40 30 670 140], ...
                'Value',{'Status: ready.'});

        end

        function openSensorEditor(app)
            editor = SensorArrayEditor;
            calibwave.ui.bringToFront(editor.UIFigure);
            appendStatus(app,'Opened SensorArrayEditor.');
        end

        function openParamEditor(app)
            editor = CalibrationParameterEditor;
            calibwave.ui.bringToFront(editor.UIFigure);
            appendStatus(app,'Opened CalibrationParameterEditor.');
        end

        function openWaveformViewer(app)
            if isempty(app.WaveformDB)
                uialert(app.UIFigure, ...
                    'Extract waveforms before opening the viewer.', ...
                    'Missing Data');
                return;
            end

            viewerIsOpen = ~isempty(app.WaveformViewerApp) && ...
                isvalid(app.WaveformViewerApp) && ...
                ~isempty(app.WaveformViewerApp.UIFigure) && ...
                isvalid(app.WaveformViewerApp.UIFigure);

            if viewerIsOpen
                app.WaveformViewerApp.setWaveformDB(app.WaveformDB);
            else
                app.WaveformViewerApp = WaveformViewer(app.WaveformDB);
            end
            calibwave.ui.bringToFront(app.WaveformViewerApp.UIFigure);

            appendStatus(app,'Opened WaveformViewer with current WaveformDB.');
        end

        function loadConfig(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load CalibConfig.mat');

            if isequal(file,0)
                return;
            end

            fullpath = fullfile(path,file);
            try
                app.CalibConfig = calibwave.io.loadCalibrationConfig(fullpath);
            catch ex
                uialert(app.UIFigure,ex.message,'Load Error');
                return;
            end
            app.ConfigPathEditField.Value = fullpath;

            appendStatus(app,'Loaded CalibConfig.');
            appendStatus(app,sprintf('Active sensors: %d',numel(app.CalibConfig.SensorArray)));
        end

        function selectBallFolder(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            folder = uigetdir(pwd,'Select ball-drop data folder');

            if isequal(folder,0)
                return;
            end

            app.BallFolderEditField.Value = folder;
            appendStatus(app,['Ball-drop folder: ' folder]);
        end

        function selectCapFolder(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            folder = uigetdir(pwd,'Select capillary-fracture data folder');

            if isequal(folder,0)
                return;
            end

            app.CapFolderEditField.Value = folder;
            appendStatus(app,['Capillary folder: ' folder]);
        end

        function extractBallWaveforms(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.CalibConfig)
                uialert(app.UIFigure,'Please load CalibConfig first.','Missing Config');
                return;
            end

            folder = app.BallFolderEditField.Value;

            if strlength(string(folder)) == 0
                uialert(app.UIFigure,'Please select ball-drop folder.','Missing Folder');
                return;
            end

            app.CalibConfig.DAQ.folder_ball = folder;

            appendStatus(app,'Extracting ball-drop waveforms...');

            BallDB = calibwave.io.extractWaveformCalibration( ...
                app.CalibConfig, ...
                folder, ...
                "Ball");

            app.WaveformDB.Ball = BallDB;
            app.WaveformDB.Config = app.CalibConfig;
            app.WaveformDB.CreatedTime = datetime("now");
            app.OpenWaveformViewerButton.Enable = 'on';

            appendStatus(app,sprintf('Extracted %d ball-drop files.',numel(BallDB.Files)));
        end

        function extractCapWaveforms(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.CalibConfig)
                uialert(app.UIFigure,'Please load CalibConfig first.','Missing Config');
                return;
            end

            folder = app.CapFolderEditField.Value;

            if strlength(string(folder)) == 0
                uialert(app.UIFigure,'Please select capillary-fracture folder.','Missing Folder');
                return;
            end

            app.CalibConfig.DAQ.folder_capillary = folder;

            appendStatus(app,'Extracting capillary-fracture waveforms...');

            CapDB = calibwave.io.extractWaveformCalibration( ...
                app.CalibConfig, ...
                folder, ...
                "Capillary");

            app.WaveformDB.Capillary = CapDB;
            app.WaveformDB.Config = app.CalibConfig;
            app.WaveformDB.CreatedTime = datetime("now");
            app.OpenWaveformViewerButton.Enable = 'on';

            appendStatus(app,sprintf('Extracted %d capillary files.',numel(CapDB.Files)));
        end

        function saveWaveformDB(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            if isempty(app.WaveformDB)
                uialert(app.UIFigure,'No waveform database to save yet.','Missing Data');
                return;
            end

            [file,path] = uiputfile('WaveformDB.mat','Save WaveformDB');

            if isequal(file,0)
                return;
            end

            WaveformDB = app.WaveformDB;
            calibwave.io.saveWaveformDB(fullfile(path,file),WaveformDB);
            app.OpenWaveformViewerButton.Enable = 'on';

            appendStatus(app,'Saved WaveformDB.');
        end

        function appendStatus(app,msg)

            old = app.StatusTextArea.Value;
            if ischar(old)
                old = {old};
            end

            app.StatusTextArea.Value = [old; {char(msg)}];
        end
    end
end
