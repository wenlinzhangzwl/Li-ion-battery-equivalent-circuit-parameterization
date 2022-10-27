%% parameterization_direct.m
% 
% This script parameterizes a 1st, 2nd or 3rd order ECM using the direct 
% optimization described in DOI: 10.1109/ITEC53557.2022.9814019
% 
% Script assumes that positive current = discharge & negative current = charge. 
% 
% Author: Wenlin Zhang (zhanw9@mcmaster.ca)
% Date: Oct 18, 2022
% Github: https://github.com/wenlinzhangzwl/Li-ion-battery-equivalent-circuit-parameterization

clear
clc

%% Settings

% Add folders to path
settings.folders.current = cd; 
settings.folders.functions = '..\scripts\functions\'; 
settings.folders.data = '..\data\'; 
settings.folders.result = '..\results\';
addpath(settings.folders.current, settings.folders.functions, settings.folders.data, settings.folders.result)

% Set cell properties
settings.cell.name = "EVE280";
switch settings.cell.name
    case "EVE280"
        settings.cell.Vmax = 3.65; 
        settings.cell.Vmin = 2.5;
        settings.cell.capacity_Ah_nominal = 280; 
        settings.cell.capacity_Ah_actual = 273.2; % from capacity test 
end

% Optimization settings
settings.data.deltaT = 0.1; % sampling period
settings.data.dataSet = ["NEDC_25degC_0p8"; "PUL_25degC_0p8_15min"; "PUL_25degC_0p8_1min"]; % input file name
% Problems: NEDC_25degC_0p8, PUL_25degC_0p8_15min
settings.optim.method = "PSO"; % can use "LS", "PSO" or "GA"
settings.ECM_info.order = 3;  % set ECM order

%% Run optimization
 
for dataNum = 1:height(settings.data.dataSet)

    % Load initial guess
    settings.parameters.SOC_breakpoints = [1:-0.01:0.9, 0.85:-0.05:0.1, 0.09:-0.01:0];
    settings.parameters.num_of_breakpoints = length(settings.parameters.SOC_breakpoints);
    settings.parameters.param = parameter_initialization(settings); % set initial guess & bounds of the parameters
    settings.parameters.param.SOC = settings.parameters.SOC_breakpoints; 

    % Load dataset to optimize based on
    dataSample = settings.data.dataSet(dataNum); % Name of the data optimized on
    load(dataSample + ".mat", "meas")

    % Divide dataset into segments by SOC
    segments = condition_and_split_data(settings, meas);

    % Set the initial guess of the OCV based on the average voltage of the segment
    settings.parameters.param.Em = [settings.cell.Vmax, transpose(cell2mat(segments(:, 4)))];
    settings.parameters.param.EmMin = settings.parameters.param.Em * 0.95; 
    settings.parameters.param.EmMax = settings.parameters.param.Em * 1.1;

    % Plot segments for validation
    figure("WindowStyle", "docked");
    ax(1) = subplot(2, 1, 1); 
    ax(2) = subplot(2, 1, 2); 
    for i = 1:height(segments)
        axes(ax(1)); hold on; plot(segments{i, 3}.Time, segments{i, 3}.Current)
        axes(ax(2)); hold on;  plot(segments{i, 3}.Time, segments{i, 3}.Voltage)
    end
    linkaxes(ax, 'x');

    % Delete unnecessary data to save memory
    clear meas

    for i = 1:height(segments) % optimize each segment
        %% Set parameters & initial states for each segment
    
        if i > 1
            
            % Load parameters (if necessary)
            if ~exist('optObj_prev', 'var')
                filename = settings.folders.result + "\temp\Parameters_direct_" + dataSample + "_" + string(settings.ECM_info.order) + "RC_" + string(i-1) + ".mat";
                load(filename)
                optObj_prev = optObj_current; 
                optObj_current = [];
            end

            % Set parameters to be optimized
            param = settings.parameters.param;
            optObj_current.SOC = [param.SOC(i+1)];
            optObj_current.param = [param.Em(i+1); param.R0(i+1); param.Rx(1:end, i+1); param.Tx(1:end, i+1)]; 
            optObj_current.lb = [param.EmMin(i+1); param.R0Min(i+1); param.RxMin(1:end, i+1); param.TxMin(1:end, i+1)]; 
            optObj_current.ub = [param.EmMax(i+1); param.R0Max(i+1); param.RxMax(1:end, i+1); param.TxMax(1:end, i+1)]; 
            optObj_current.initStates = optObj_prev.endStates;

        elseif i == 1
            param = settings.parameters.param;  % Init guesses (struct)

            % Set parameters to be optimized
            optObj_current.SOC = [param.SOC(1); param.SOC(2)];
            optObj_current.param = [param.Em(1); param.R0(1); param.Rx(1:end, 1); param.Tx(1:end, 1); ...
                         param.Em(2); param.R0(2); param.Rx(1:end, 2); param.Tx(1:end, 2)]; 
            optObj_current.lb = [param.EmMin(1); param.R0Min(1); param.RxMin(1:end, 1); param.TxMin(1:end, 1); ...
                  param.EmMin(2); param.R0Min(2); param.RxMin(1:end, 2); param.TxMin(1:end, 2)]; 
            optObj_current.ub = [param.EmMax(1); param.R0Max(1); param.RxMax(1:end, 1); param.TxMax(1:end, 1); ...
                  param.EmMax(2); param.R0Max(2); param.RxMax(1:end, 2); param.TxMax(1:end, 2)]; 

            % Set initial states
            optObj_current.initStates.I_RC = [0, 0, 0];
            optObj_current.initStates.Vt = segments{i, 3}.Voltage(1);
            optObj_current.initStates.SOC = segments{1, 3}.SOC(1);

            % Set previously optimized parameters
            optObj_prev = [];
        end

        %% Optimize

        % Set initial conditions based on segment
%         optObj_current.initStates.I_RC = [0, 0, 0];
%         optObj_current.initStates.Vt = optObj_current.segment.Voltage(1);
%         optObj_current.initStates.SOC = optObj_current.segment.SOC(1);

        % Settings
        optObj_current.segment = segments{i, 3}; % input current
        settings.optim.batt_model = @ecm;  % battery model
        fun = @(param_opt)parameterization_Objective(settings, optObj_current, optObj_prev, param_opt); % objective function
        % 'param_opt' is a placeholder, should be a row vector of length 'nvars'

        % Optimize
        x = parameterization_Optimize(fun, optObj_current, settings.optim.method); 
        
        % Parameters before optimization
        optObj_current.param_before = optObj_current.param; 
        optObj_current.param_before_table = format_opt_param(optObj_current.param_before, settings.ECM_info.order, "vector2table");
        optObj_current.param_before_table.SOC = optObj_current.SOC; 

        % Parameters after optimization
        optObj_current.param_after = x'; 
        optObj_current.param_after_table = format_opt_param(optObj_current.param_after, settings.ECM_info.order, "vector2table");
        optObj_current.param_after_table.SOC = optObj_current.SOC; 

        %% Update states after optimization

        current_dmd = optObj_current.segment.Current; 
        capacity_Ah = settings.cell.capacity_Ah_actual;
        initStates = optObj_current.initStates; 

        % Calculate Vt before optimization
        param = format_opt_param(settings.parameters.param, settings.ECM_info.order, "struct2table"); 
        [Vt_before, ~, ~] = settings.optim.batt_model(settings, current_dmd, initStates, param, capacity_Ah); 

        % Update parameters in "settings"
        param = format_opt_param(optObj_current.param_after, settings.ECM_info.order, "vector2struct");
        if i > 1
            [settings.parameters.param.Em(i+1),...
             settings.parameters.param.R0(i+1),...
             settings.parameters.param.Rx(1:end, i+1),...
             settings.parameters.param.Tx(1:end, i+1)]...
                = deal(param.Em, param.R0, param.Rx', param.Tx'); 
        elseif i == 1
            [settings.parameters.param.Em(1:2),...
             settings.parameters.param.R0(1:2),...
             settings.parameters.param.Rx(1:end, 1:2),...
             settings.parameters.param.Tx(1:end, 1:2)]...
                = deal(param.Em(1:2), param.R0(1:2), param.Rx', param.Tx'); 
        end

        % Calculate Vt after optimization
        param = format_opt_param(settings.parameters.param, settings.ECM_info.order, "struct2table"); 
        [Vt_after, ~, endStates] = settings.optim.batt_model(settings, current_dmd, initStates, param, capacity_Ah);  

        % Plot the measured and simulated data.
        figName = 'Pulse ' + string(i);
        figure('Name', figName, 'WindowStyle', 'docked'); hold on
        plot(optObj_current.segment.Time, optObj_current.segment.Voltage, 'color', '#0072BD')
        plot(optObj_current.segment.Time, Vt_before, 'color', '#D95319');
        plot(optObj_current.segment.Time, Vt_after, 'color', '#77AC30');
        title(append('Simulated and Measured Responses Before Estimation (Pulse ', string(i), ')'))
        legend('Measured Vt', 'Before Optim', 'After Optim');
        
        % Update end states
        optObj_current.endStates = endStates;

        % Save settings and parameters
        param = format_opt_param(settings.parameters.param, settings.ECM_info.order, "struct2table"); 
        if i ~= height(segments)
            filename = settings.folders.result + "\temp\Parameters_direct_" + dataSample + "_" + string(settings.ECM_info.order) + "RC_" + string(i) + ".mat";
        else
            filename = settings.folders.result + "\Parameters_direct_" + dataSample + "_" + string(settings.ECM_info.order) + "RC.mat";
        end
        save(filename, 'settings', 'optObj_current')

        % Update optObj
        optObj_prev = optObj_current; 
        optObj_current = [];

    end

end

function segments = condition_and_split_data(settings, meas)
% Formats input data and divide into segments by SOC

        % Delete unnecessary fields
        fields = {'TimeStamp','StepTime','Procedure','Wh','Power','Battery_Temp_degC', 'Temp', 'Temp_neg', 'Temp_pos'};
        class_meas = class(meas); 
        if class_meas == "struct"
            meas_optim = struct2table(meas);
        elseif class_meas == "table"
            meas_optim = meas; 
        end
        for i = 1:length(fields)
            try
                meas_optim = removevars(meas_optim, fields(i));
            catch
                % Do nothing
            end
        end

        % Delete inf & NaN
        meas_optim = meas_optim( ~any( isnan( meas_optim.Time ) | isinf( meas_optim.Time ), 2 ),: );
        meas_optim = meas_optim( ~any( isnan( meas_optim.Current ) | isinf( meas_optim.Current ), 2 ),: );
        meas_optim = meas_optim( ~any( isnan( meas_optim.Voltage ) | isinf( meas_optim.Voltage ), 2 ),: );

        % Delete anything after Vmin is reached
        ind = find(meas_optim.Voltage <= settings.cell.Vmin, 1);
        if ~isempty(ind)
            meas_optim = meas_optim(1:ind, :);
        end

        % Make sure data is in the correct format
        Q = abs(meas_optim.Ah(end)-meas_optim.Ah(1));
%         meas_optim.Current = -meas_optim.Current; % Assumes input data current has opposite sign convension
        meas_optim.Ah = meas_optim.Ah - meas_optim.Ah(1);
        meas_optim.SOC = 1 - (-meas_optim.Ah)/Q;
        meas_optim.Time = meas_optim.Time - meas_optim.Time(1);

        % Divide data into segments by SOC
        SOC = settings.parameters.param.SOC;
        validateattributes(SOC, "double", "decreasing")
        for i = 1:length(SOC)-1
            i1 = find(meas_optim.SOC <= SOC(i), 1);
            i2 = find(meas_optim.SOC <= SOC(i+1), 1);
            iStart = min(i1, i2); 
            iEnd = min(height(meas_optim.SOC), max(i1, i2)+100); 
            if isempty(iEnd)
                iEnd = height(meas_optim);
                segments{i, 1} = [SOC(i), SOC(i+1)];
                segments{i, 2} = [iStart, iEnd];
                segments{i, 3} = meas_optim(iStart:iEnd, :);
                break
            end
            segments{i, 1} = [SOC(i), SOC(i+1)];
            segments{i, 2} = [iStart, iEnd];
            segments{i, 3} = meas_optim(iStart:iEnd, :);
            segments{i, 4} = mean(meas_optim.Voltage(iStart:iEnd)); 
        end
end

