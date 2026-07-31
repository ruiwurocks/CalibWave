classdef SensorArrayEditor < matlab.apps.AppBase

    properties
        UIFigure
        UIAxes
        SensorTable

        SpacingEditField
        NEditField
        ThicknessEditField

        GenerateButton
        ClearButton
        SaveButton
        LoadButton

        InfoLabel

        SensorGrid          % full N x N possible positions
        SensorArray         % working full grid; labelled sensors are active
        SensorHandles
        SelectedIndex = []
    end

    methods

        function app = SensorArrayEditor
            createComponents(app);
            generateArray(app);
        end

        function createComponents(app)

            app.UIFigure = uifigure('Name','Sensor Array Editor');
            app.UIFigure.Position = [100 100 1100 650];
            app.UIFigure.WindowButtonMotionFcn = @(src,event) mouseMove(app);

            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [30 110 600 500];

            uilabel(app.UIFigure,'Text','Spacing (mm)', ...
                'Position',[670 590 100 22]);
            app.SpacingEditField = uieditfield(app.UIFigure,'numeric', ...
                'Position',[780 590 80 22], ...
                'Value',40);

            uilabel(app.UIFigure,'Text','N sensors/side', ...
                'Position',[670 555 100 22]);
            app.NEditField = uieditfield(app.UIFigure,'numeric', ...
                'Position',[780 555 80 22], ...
                'Value',7);

            uilabel(app.UIFigure,'Text','Plate h (mm)', ...
                'Position',[670 520 100 22]);
            app.ThicknessEditField = uieditfield(app.UIFigure,'numeric', ...
                'Position',[780 520 80 22], ...
                'Value',50);

            app.GenerateButton = uibutton(app.UIFigure,'push', ...
                'Text','Generate Array', ...
                'Position',[900 590 150 28], ...
                'ButtonPushedFcn',@(src,event) generateArray(app));

            app.ClearButton = uibutton(app.UIFigure,'push', ...
                'Text','Clear Labels', ...
                'Position',[900 550 150 28], ...
                'ButtonPushedFcn',@(src,event) clearLabels(app));

            app.SaveButton = uibutton(app.UIFigure,'push', ...
                'Text','Save Sensor Map', ...
                'Position',[900 510 150 28], ...
                'ButtonPushedFcn',@(src,event) saveSensorMap(app));

            app.LoadButton = uibutton(app.UIFigure,'push', ...
                'Text','Load Sensor Map', ...
                'Position',[900 470 150 28], ...
                'ButtonPushedFcn',@(src,event) loadSensorMap(app));

            app.InfoLabel = uilabel(app.UIFigure, ...
                'Text','Move mouse near a sensor to show r and take-off angle.', ...
                'Position',[30 70 850 25]);

            app.SensorTable = uitable(app.UIFigure);
            app.SensorTable.Position = [660 120 410 330];
            app.SensorTable.ColumnEditable = ...
                [false false false false false true true true];
            app.SensorTable.CellEditCallback = ...
                @(src,event) tableEdited(app,event);
            app.SensorTable.CellSelectionCallback = ...
                @(src,event) tableSelected(app,event);
        end

        function generateArray(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            N = round(app.NEditField.Value);
            spacing_mm = app.SpacingEditField.Value;
            h_mm = app.ThicknessEditField.Value;

            if mod(N,2) == 0
                uialert(app.UIFigure,'N must be odd.','Input Error');
                return;
            end

            app.SensorGrid = calibwave.geometry.createSensorArray(N, spacing_mm, h_mm);
            app.SensorArray = app.SensorGrid;
            app.SelectedIndex = [];

            updateTable(app);
            plotSensorArray(app);
        end

        function SensorArray = createSensorArray(app, N, spacing_mm, h_mm)
            SensorArray = calibwave.geometry.createSensorArray(N, spacing_mm, h_mm);
        end

        function plotSensorArray(app)

            cla(app.UIAxes);
            hold(app.UIAxes,'on');

            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';
            app.UIAxes.XColor = 'none';
            app.UIAxes.YColor = 'none';
            title(app.UIAxes,'');

            nSensor = numel(app.SensorArray);
            app.SensorHandles = gobjects(nSensor,1);

            for i = 1:nSensor

                x_mm = app.SensorArray(i).x * 1e3;
                y_mm = app.SensorArray(i).y * 1e3;

                hasLabel = strlength(string(app.SensorArray(i).SensorLabel)) > 0 || ...
                           strlength(string(app.SensorArray(i).ChannelLabel)) > 0;

                if hasLabel
                    markerFace = [1.0 0.75 0.85];   % labelled real sensor
                    app.SensorArray(i).IsActive = true;
                else
                    markerFace = [1 1 1];           % empty possible position
                    app.SensorArray(i).IsActive = false;
                end

                app.SensorHandles(i) = plot(app.UIAxes, x_mm, y_mm, 'o', ...
                    'MarkerSize',18, ...
                    'MarkerFaceColor',markerFace, ...
                    'MarkerEdgeColor',[0 0 0], ...
                    'LineWidth',1.2, ...
                    'ButtonDownFcn',@(src,event) sensorClicked(app,i));

                labelText = string(app.SensorArray(i).ChannelLabel);

                text(app.UIAxes, x_mm, y_mm, labelText, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',9, ...
                    'FontWeight','bold', ...
                    'HitTest','off');
            end

            x_all = [app.SensorArray.x] * 1e3;
            y_all = [app.SensorArray.y] * 1e3;

            margin = app.SpacingEditField.Value * 0.9;

            xlim(app.UIAxes, [min(x_all)-margin, max(x_all)+margin]);
            ylim(app.UIAxes, [min(y_all)-margin, max(y_all)+margin]);

            axis(app.UIAxes,'equal');
            hold(app.UIAxes,'off');
        end

        function sensorClicked(app, idx)

            app.SelectedIndex = idx;
            highlightSensor(app, idx);

            try
                app.SensorTable.Selection = idx;
            catch
            end
        end

        function highlightSensor(app, idx)

            if isempty(app.SensorHandles) || idx > numel(app.SensorHandles)
                return;
            end

            for i = 1:numel(app.SensorHandles)
                app.SensorHandles(i).LineWidth = 1.2;
                app.SensorHandles(i).MarkerEdgeColor = [0 0 0];
            end

            app.SensorHandles(idx).LineWidth = 2.5;
            app.SensorHandles(idx).MarkerEdgeColor = [1 0 0];
        end

        function mouseMove(app)

            if isempty(app.SensorArray)
                return;
            end

            cp = app.UIAxes.CurrentPoint;
            x_mouse = cp(1,1);
            y_mouse = cp(1,2);

            xlim_now = app.UIAxes.XLim;
            ylim_now = app.UIAxes.YLim;

            if x_mouse < xlim_now(1) || x_mouse > xlim_now(2) || ...
               y_mouse < ylim_now(1) || y_mouse > ylim_now(2)
                return;
            end

            x_all = [app.SensorArray.x] * 1e3;
            y_all = [app.SensorArray.y] * 1e3;

            d = sqrt((x_all - x_mouse).^2 + (y_all - y_mouse).^2);
            [dmin, idx] = min(d);

            spacing_mm = app.SpacingEditField.Value;
            threshold = spacing_mm * 0.35;

            if dmin < threshold
                S = app.SensorArray(idx);

                app.InfoLabel.Text = sprintf( ...
                    'Index %d | Channel: %s | Sensor: %s | x = %.1f mm | y = %.1f mm | r = %.1f mm | theta = %.2f deg', ...
                    S.Index, string(S.ChannelLabel), string(S.SensorLabel), ...
                    S.x*1e3, S.y*1e3, S.r*1e3, S.theta);
            end
        end

        function updateTable(app)

            n = numel(app.SensorArray);

            Index = zeros(n,1);
            x_mm = zeros(n,1);
            y_mm = zeros(n,1);
            r_mm = zeros(n,1);
            theta_deg = zeros(n,1);
            SensorLabel = strings(n,1);
            ChannelLabel = strings(n,1);
            IsActive = false(n,1);

            for i = 1:n
                hasLabel = strlength(string(app.SensorArray(i).SensorLabel)) > 0 || ...
                           strlength(string(app.SensorArray(i).ChannelLabel)) > 0;

                app.SensorArray(i).IsActive = hasLabel;

                Index(i) = app.SensorArray(i).Index;
                x_mm(i) = app.SensorArray(i).x * 1e3;
                y_mm(i) = app.SensorArray(i).y * 1e3;
                r_mm(i) = app.SensorArray(i).r * 1e3;
                theta_deg(i) = app.SensorArray(i).theta;
                SensorLabel(i) = string(app.SensorArray(i).SensorLabel);
                ChannelLabel(i) = string(app.SensorArray(i).ChannelLabel);
                IsActive(i) = app.SensorArray(i).IsActive;
            end

            T = table(Index, x_mm, y_mm, r_mm, theta_deg, ...
                SensorLabel, ChannelLabel, IsActive);

            app.SensorTable.Data = T;
        end

        function tableEdited(app,event)

            row = event.Indices(1);
            col = event.Indices(2);
            T = app.SensorTable.Data;

            colName = app.SensorTable.ColumnName{col};

            switch colName
                case 'SensorLabel'
                    app.SensorArray(row).SensorLabel = string(T.SensorLabel(row));
                case 'ChannelLabel'
                    app.SensorArray(row).ChannelLabel = string(T.ChannelLabel(row));
                case 'IsActive'
                    app.SensorArray(row).IsActive = logical(T.IsActive(row));
            end

            updateTable(app);
            plotSensorArray(app);

            if ~isempty(app.SelectedIndex)
                highlightSensor(app, app.SelectedIndex);
            end
        end

        function tableSelected(app,event)

            if isempty(event.Indices)
                return;
            end

            idx = event.Indices(1);
            app.SelectedIndex = idx;
            highlightSensor(app, idx);
        end

        function clearLabels(app)

            for i = 1:numel(app.SensorArray)
                app.SensorArray(i).SensorLabel = "";
                app.SensorArray(i).ChannelLabel = "";
                app.SensorArray(i).IsActive = false;
            end

            app.SensorGrid = app.SensorArray;

            updateTable(app);
            plotSensorArray(app);
        end

        function saveSensorMap(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uiputfile('SensorMap.mat','Save Sensor Map');

            if isequal(file,0)
                return;
            end

            SensorGrid = app.SensorArray;

            sensorLabels = string({SensorGrid.SensorLabel});
            channelLabels = string({SensorGrid.ChannelLabel});

            keepID = strlength(sensorLabels) > 0 | strlength(channelLabels) > 0;

            SensorArray = SensorGrid(keepID);

            for i = 1:numel(SensorArray)
                SensorArray(i).Index = i;
                SensorArray(i).IsActive = true;
            end

            MapInfo.Spacing_mm = app.SpacingEditField.Value;
            MapInfo.N = app.NEditField.Value;
            MapInfo.h_mm = app.ThicknessEditField.Value;
            MapInfo.CreatedTime = datetime("now");
            MapInfo.Note = 'SensorGrid contains full possible positions; SensorArray contains labelled active sensors only.';

            calibwave.io.saveSensorMap( ...
                fullfile(path,file),SensorGrid,SensorArray,MapInfo);

            uialert(app.UIFigure, ...
                sprintf('Saved %d labelled sensors and full %d-position grid.', ...
                numel(SensorArray), numel(SensorGrid)), ...
                'Sensor Map Saved');
        end

        function loadSensorMap(app)
            restoreFocus = onCleanup(@() calibwave.ui.bringToFront(app.UIFigure));

            [file,path] = uigetfile('*.mat','Load Sensor Map');

            if isequal(file,0)
                return;
            end

            try
                [app.SensorGrid,activeSensors,MapInfo] = ...
                    calibwave.io.loadSensorMap(fullfile(path,file));
            catch ex
                uialert(app.UIFigure,ex.message,'Load Error');
                return;
            end

            if ~isempty(MapInfo)
                if isfield(MapInfo,'Spacing_mm')
                    app.SpacingEditField.Value = MapInfo.Spacing_mm;
                end
                if isfield(MapInfo,'N')
                    app.NEditField.Value = MapInfo.N;
                end
                if isfield(MapInfo,'h_mm')
                    app.ThicknessEditField.Value = MapInfo.h_mm;
                end
            end

            app.SensorArray = app.mergeLabelsIntoGrid(app.SensorGrid, activeSensors);
            app.SensorGrid = app.SensorArray;

            app.SelectedIndex = [];

            updateTable(app);
            plotSensorArray(app);
        end

        function SensorGrid = mergeLabelsIntoGrid(app, SensorGrid, SensorArray)
            SensorGrid = calibwave.geometry.mergeLabelsIntoGrid( ...
                SensorGrid, SensorArray);
        end
    end
end
