%% batterymodel_run.m
% 
% This script runs a 1st, 2nd or 3rd order ECM with parameters specified by
% the user
%
% Script assumes that positive current = discharge & negative current = charge. 
% 
% Author: Wenlin Zhang (zhanw9@mcmaster.ca)
% Date: Oct 18, 2022 
% Github: https://github.com/wenlinzhangzwl/Li-ion-battery-equivalent-circuit-parameterization


clear
clc

% Folders
settings.folders.current = cd; 
settings.folders.functions = '..\scripts\functions\'; 
settings.folders.data = '..\data\'; 
settings.folders.result = '..\results\';
addpath(settings.folders.current, settings.folders.functions, settings.folders.data, settings.folders.result)

% Test settings
settings.cycler = "Arbin-Lynx";
settings.cell.name = "MachE";

save_rmse_of_each_parameter_set = 0;
save_rmse_of_all_parameter_sets = 0; 
plot_based_on_time = 1; 

% Set test profile & parameter set 
% profileSet = ["HWFET"; "UDDS"; "US06"; "NEDC"; "MIX"];
profileSet = ["US06"];
paramSet = ["Parameters_analytical_PUL_25degC_0p8_30min_3RC";];

% RMSE for each case
rmse = zeros(height(profileSet)*height(paramSet), 5); 
rmse = num2cell(rmse);

for paramNum = 1:height(paramSet)

    % Load parameter set
    inputParameter = paramSet(paramNum); 
    load(inputParameter + ".mat")

    % Make sure SOC is increasing
    param = settings.parameters.param; 
    if class(settings.parameters.param) == "Battery.Parameters"
        param = format_opt_param(param, settings.ECM_info.order, "param2table");   
        settings.parameters.param = param;
    elseif class(settings.parameters.param) == "struct"
        param = format_opt_param(param, settings.ECM_info.order, "struct2table");   
        settings.parameters.param = param;
    end
    if param.SOC(1) > param.SOC(2)
        param = flip(param); 
    end
    settings.parameters.param = param; 
    validateattributes(settings.parameters.param.SOC, {'double'}, {'increasing'})

    % Run model for the current profile
    for profileNum = 1:height(profileSet) %parfor profileNum = 1:height(profileSet)
        %% Load test profiles

        inputProfile = profileSet(profileNum);

        % Load test data.
        deltaT = 0.1; % Set sampling time to 0.1s unless updated later
        switch settings.cell.name
            case "EVE280"
                switch inputProfile
                    case 'US06'
                        load("US06_25degC_0p8.mat", "meas");
                    case 'HWFET'
                        load("HWFET_25degC_0p8.mat", "meas");
                    case 'UDDS'
                        load("UDDS_25degC_0p8.mat", "meas");
                    case 'NEDC'
                        load("NEDC_25degC_0p8.mat", "meas");
                    case 'MIX'
                        load("MIX_25degC_0p8.mat", "meas");
                end
        end

        % Convert struct to table
        try
            meas_t = struct2table(meas);
        catch
            meas_t = meas; 
        end

        % Formatting & calculate SOC
        Q = abs(meas_t.Ah(end) - meas_t.Ah(1));
        meas_t.Ah = meas_t.Ah - meas_t.Ah(1);
        meas_t.Time = meas_t.Time - meas_t.Time(1);
        meas_t.SOC = 1 - (-meas_t.Ah)/Q;
        meas_t = meas_t( ~any( isnan( meas_t.Current ) | isinf( meas_t.Current ), 2 ),: ); % Delete inf & NaN

        % Delete anything after Vmin was reached
        ind = find(meas_t.Voltage <= settings.cell.Vmin, 1);
        if ~isempty(ind)
            meas_t = meas_t(1:ind, :);
            Q = abs(meas_t.Ah(end)-meas_t.Ah(1));
        end
        
        %% Run model

        ECM_order = settings.ECM_info.order;

        % Initial states
        initStates.SOC = meas_t.SOC(1); 
        initStates.I_RC = zeros(1, ECM_order); 
        initStates.Vt = meas_t.Voltage(1);
        
        [Vt, ~, ~] = ecm(settings, meas_t.Current, initStates, settings.parameters.param, settings.cell.capacity_Ah_actual);

        initStates = [];  % Overwrite var so it can be recognized as a temporary variable by parfor

        %% Calculate simulation results

        % Calculate error
        Vt_err = Vt - meas_t.Voltage;
        Vt_rmse = sqrt(mean((meas_t.Voltage(1:height(Vt)) - Vt).^2));
        Vt_max_err = max(abs(Vt_err)); 

        % Write result to "rmse_temp"
        rmse_temp{profileNum, :} = [{inputParameter}, {inputProfile}, {Vt_rmse}, {Vt_max_err}, {[meas_t.Time, meas_t.SOC, meas_t.Voltage, Vt]}]; 
    end

    % Write 'rmse_temp' to 'rmse'
    ind = (paramNum-1)*height(profileSet) + 1; 
    for i = 1:height(rmse_temp)
        % Each parameter set run
        [rmse_param{i, 1}, rmse_param{i, 2}, rmse_param{i, 3}, rmse_param{i, 4}, rmse_param{i, 5}] = ...
            deal(rmse_temp{i,1}{1, 1}, rmse_temp{i,1}{1, 2}, rmse_temp{i,1}{1, 3}, rmse_temp{i,1}{1, 4}, rmse_temp{i,1}{1, 5}); 
        
        % All runs
        [rmse{ind, 1}, rmse{ind, 2}, rmse{ind, 3}, rmse{ind, 4}, rmse{ind, 5}] = ...
            deal(rmse_temp{i,1}{1, 1}, rmse_temp{i,1}{1, 2}, rmse_temp{i,1}{1, 3}, rmse_temp{i,1}{1, 4}, rmse_temp{i,1}{1, 5}); 
        ind = ind + 1; 
    end

    %% Plot results for the current set of parameters 

%     % Plot Vt_err
%     figurename = append('Vt_err (', string(inputParameter), ')');
%     figure('WindowStyle', 'docked', 'Name', figurename); hold on
%     legend_txt = []; 
%     for i = 1:height(rmse_temp)
%         SOC_i = rmse_temp{i, 1}{1, 5}(:, 2); 
%         Vt_err_i = rmse_temp{i, 1}{1, 5}(:, 4) - rmse_temp{i, 1}{1, 5}(:, 3); 
%         plot(SOC_i, Vt_err_i*1000); 
% 
%         legend_txt = [legend_txt; rmse_temp{i, 1}{1, 2}];
%     end
%     grid on; title(figurename, 'Interpreter', 'none');
%     legend(legend_txt, 'Interpreter', 'none');

    % Plot Vt
    figurename = append('Vt (', string(inputParameter), ')');
    figure('WindowStyle', 'docked', 'Name', figurename);
    for i = 1:height(rmse_temp)
        axes{i, 1} = subplot(height(rmse_temp), 1, i); hold on

        time_i = rmse_temp{i, 1}{1, 5}(:, 1); 
        SOC_i = rmse_temp{i, 1}{1, 5}(:, 2); 
        Voltage_i = rmse_temp{i, 1}{1, 5}(:, 3);
        Vt_sim_i = rmse_temp{i, 1}{1, 5}(:, 4); 
        inputProfile_i = rmse_temp{i, 1}{1, 2}; 
        rmse_i = round(rmse_temp{i, 1}{1, 3}*1000, 2); 
        max_err_i = round(rmse_temp{i, 1}{1, 4}*1000, 2); 

        if plot_based_on_time == 0
            plot(SOC_i, Voltage_i);
            plot(SOC_i, Vt_sim_i);
            xlim([-0.01, 1.01]); 
        elseif plot_based_on_time == 1
            plot(time_i, Voltage_i);
            plot(time_i, Vt_sim_i);
        end

        grid on; legend(['exp'; 'sim']); 
        title_txt = inputProfile_i + " (RMSE:" + string(rmse_i) + "mV, Max error:" + string(max_err_i) + "mV)";
        title(title_txt, 'Interpreter','none');
        
    end

    % Plot parameters (after)
    var_num = (width(param)-1)/3;
    
    var_names = string(param.Properties.VariableNames);
    ind = contains(var_names, "Min");
    var_names(ind) = []; 
    ind = contains(var_names, "Max");
    var_names(ind) = []; 
    ind = contains(var_names, "SOC");
    var_names(ind) = []; 

    figure('WindowStyle', 'docked', 'Name', inputParameter);
    for i = 1:var_num
        ax(i) = subplot(2, var_num/2, i); 
        hold on
    
        SOC_i = param.SOC;
        var_i = param.(var_names(i));
        plot(SOC_i, var_i, '.-')
    
        var_name_i = var_names(i);
        title(var_name_i, "Interpreter","none"); 
        grid on; xlabel('SOC');
    end
    linkaxes([ax], 'x')

    % Save results
    filename = settings.folders.result + "\RMSE_" + inputParameter; 
    rmse_param_noData = rmse_param(:, 1:4); 
    
    if save_rmse_of_each_parameter_set == 1
        save(filename, "rmse_param", 'rmse_param_noData');
    end

end

filename = settings.folders.result + "\RMSE"; 
try
    mkdir(filename)
end
rmse_noData = rmse(:, 1:4); 
if save_rmse_of_all_parameter_sets == 1
    save(filename, "rmse", 'rmse_noData');
end