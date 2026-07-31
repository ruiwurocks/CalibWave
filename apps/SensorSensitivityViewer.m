classdef SensorSensitivityViewer < matlab.apps.AppBase

    properties
        UIFigure
        AxAll
        AxAvg
        SensData
    end

    methods
        function app = SensorSensitivityViewer(SensData)
            app.SensData = SensData;
            app.createComponents();
            app.plotSensitivity();
        end

        function createComponents(app)
            app.UIFigure = uifigure('Name','Sensor Sensitivity');
            app.UIFigure.Position = [250 120 900 800];

            app.AxAll = uiaxes(app.UIFigure);
            app.AxAll.Position = [80 400 780 300];
            box(app.AxAll,'on');
            grid(app.AxAll,'off');
            app.AxAll.LineWidth = 1.2;

            app.AxAvg = uiaxes(app.UIFigure);
            app.AxAvg.Position = [80 80 780 300];
            box(app.AxAvg,'on');
            grid(app.AxAvg,'off');
            app.AxAvg.LineWidth = 1.2;
        end

        function plotSensitivity(app)
            calibwave.plotting.plotSensitivity( ...
                app.AxAll,app.AxAvg,app.SensData);
        end

        function exportLowerPanelOnly(app,fileBase,fileType)
            calibwave.plotting.exportAxes(app.AxAvg,fileBase,fileType);
        end
    end
end
