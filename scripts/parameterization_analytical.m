%% parameterization_analytical.m
% 
% This script parameterizes a 1st, 2nd or 3rd order ECM using the analytical 
% method described in DOI: 10.1109/ITEC53557.2022.9814019
% 
% Details on the Mathworks functions can be found at: 
% https://www.mathworks.com/help/autoblks/ug/generate-parameter-data-for-estimations-circuit-battery-block.html
%
% Script assumes that positive current = discharge & negative current = charge. 
% 
% Author: Wenlin Zhang (zhanw9@mcmaster.ca)
% Date: Oct 18, 2022 
% Github: https://github.com/wenlinzhangzwl/Li-ion-battery-equivalent-circuit-parameterization

clear
clc

% ECM order
settings.ECM_info.order = 3;  % Order of the ECM

%% Load data from the experiment

% Folders
settings.folders.current = cd; 
settings.folders.functions = "..\scripts\functions"; 

% Test settings
settings.cell.name = "EVE280";
switch settings.cell.name
    case "EVE280"
        settings.folders.data = "..\data"; 
        settings.folders.result = "..\results"; 
        settings.cell.Vmax = 3.65; 
        settings.cell.Vmin = 2.5;
        settings.cell.capacity_Ah_nominal = 280; 
        settings.cell.capacity_Ah_actual = 273.2;
end

try
    mkdir(settings.folders.result);
end

addpath(settings.folders.current, settings.folders.functions, settings.folders.data, settings.folders.result);

% Load data
file = "PUL_25degC_0p8_15min"; % input file name
settings.data.filename = file +".mat"; 
settings.data.deltaT = 0.1; % sampling period
load(settings.data.filename, 'meas'); 
try
    meas = struct2table(meas);
end

% Add in an artifical data point for the function to recognize the first pulse
if meas.Current(1) ~= 0
    fake_data = meas(1, :);
    fake_data.Current = 0; 
    fake_data.Voltage = settings.cell.Vmax;

    meas.Time = meas.Time + meas.Time(2);
    meas = [fake_data; meas];
end

% Delete data where time is not strictly increasing
time_diff = meas.Time(2:end) - meas.Time(1:end-1);
ind = find(time_diff <= 0) + 1; 
meas(ind, :) = []; 
validateattributes(meas.Time, {'double'}, {'increasing'});

% Create a Battery.PulseSequency object with all measurement data
psObj = Battery.PulseSequence;
psObj.ModelName = 'BatteryEstim3RC_PTBS';
addData(psObj, meas.Time, meas.Voltage, meas.Current); % The MATLAB functions take +ve current as discharge
% psObj.plot();

% Identify the pulses within the data set
psObj.createPulses(...
    'CurrentOnThreshold',0.1,... % minimum current magnitude to identify pulse events
    'NumRCBranches', settings.ECM_info.order,... % how many RC pairs in the model
    'RCBranchesUse2TimeConstants',false,... % do RC pairs have different time constant for discharge and rest?
    'PreBufferSamples',10,... % how many samples to include before the current pulse starts
    'PostBufferSamples',10); % how many samples to include after the next pulse starts
% psObj.plotIdentifiedPulses();


%% Estimate Parameters

% Set breakpoints
settings.parameters.SOC_breakpoints = psObj.Parameters.SOC;
settings.parameters.num_of_breakpoints = length(settings.parameters.SOC_breakpoints);

% Set initial values of parameters & ub/lb
parameters_init = parameter_initialization(settings);
[psObj.Parameters.R0, psObj.Parameters.R0Min, psObj.Parameters.R0Max,...
 psObj.Parameters.Rx, psObj.Parameters.RxMin, psObj.Parameters.RxMax,...
 psObj.Parameters.Em, psObj.Parameters.EmMin, psObj.Parameters.EmMax,...
 psObj.Parameters.Tx, psObj.Parameters.TxMin, psObj.Parameters.TxMax] ...
 = deal(parameters_init.R0, parameters_init.R0Min, parameters_init.R0Max,...
        parameters_init.Rx, parameters_init.RxMin, parameters_init.RxMax,...
        parameters_init.Em, parameters_init.EmMin, parameters_init.EmMax,...
        parameters_init.Tx, parameters_init.TxMin, parameters_init.TxMax);
psObj.plotLatestParameters();

% Estimate initial R0 values
psObj.estimateInitialEmR0(...
    'SetEmConstraints',false,... %Update EmMin or EmMax values based on what we learn here
    'EstimateEm',true,... %Keep this on to perform Em estimates
    'EstimateR0',true); %Keep this on to perform R0 estimates

% Plot results
psObj.plotLatestParameters();

% Get initial Tx (Tau) values
psObj.estimateInitialTau(...
    'UpdateEndingEm',true,... %Keep this on to update Em estimates at the end of relaxations, based on the curve fit
    'ShowPlots',true,... %Set this true if you want to see plots while this runs
    'ReusePlotFigure',true,... %Set this true to overwrite the plots in the same figure
    'UseLoadData',false,... %Set this true if you want to estimate Time constants from the load part of the pulse, instead of relaxation
    'PlotDelay',0.5); %Set this to add delay so you can see the plots 

% % Plot results
psObj.plotLatestParameters(); %See what the parameters look like so far
% psObj.plotSimulationResults(); %See what the result looks like so far

% Get initial Em and Rx values using a linear system approach - pulse by pulse
psObj.estimateInitialEmRx(...
    'IgnoreRelaxation',false,... %Set this true if you want to ignore the relaxation periods during this step
    'ShowPlots',true,...  %Set this true if you want to see plots while this runs
    'ShowBeforePlots',true,... %Set this true if you want to see the 'before' value on the plots
    'PlotDelay',0.5,... %Set this to add delay so you can see the plots 
    'EstimateEm',true,... %Set this true to allow the optimizer to change Em further in this step
    'RetainEm',true,... %Set this true keep any changes made to Em in this step
    'EstimateR0',true,... %Set this true to allow the optimizer to change R0 further in this step
    'RetainR0',true); %Set this true keep any changes made to R0 in this step
psObj.plotLatestParameters(); %See what the parameters look like so far

Simulink.SimulationData.ModelLoggingInfo

% Plot results
psObj.plotLatestParameters();
if settings.ECM_info.order == 3
    psObj.plotSimulationResults();
end

%% Export initial guess
psParam = psObj.Parameters;

% Round OCV to 0.01 to make sure it's non-decreasing
psParam.EmMin = round(psObj.Parameters.EmMin, 2);
psParam.EmMax = round(psObj.Parameters.EmMax, 2);
psParam.Em = round(psObj.Parameters.Em, 2);

% Create a table of parameters
param.SOC = psParam.SOC';
[param.R0, param.Rx, param.Tx, param.OCV] = deal(psParam.R0', psParam.Rx', psParam.Tx', psParam.Em');
[param.R0Min, param.RxMin, param.TxMin, param.OCVMin] = deal(psParam.R0Min', psParam.RxMin', psParam.TxMin', psParam.EmMin');
[param.R0Max, param.RxMax, param.TxMax, param.OCVMax] = deal(psParam.R0Max', psParam.RxMax', psParam.TxMax', psParam.EmMax');
param = splitvars(struct2table(param));

%% Plot the parameters & their bounds

var_num = (width(param)-1)/3;
var_names = param.Properties.VariableNames;

figure('WindowStyle', 'docked');
for i = 1:var_num
    ax(i) = subplot(2, var_num/2, i); 
    hold on

    SOC_i = table2array(param(:, 1));
    var_i = table2array(param(:, i+1));
    min_i = table2array(param(:, i+1+var_num));
    max_i = table2array(param(:, i+1+var_num*2));

    plot(SOC_i, var_i, '.-')
    plot(SOC_i, min_i, '.-')
    plot(SOC_i, max_i, '.-')

    var_name_i = var_names{i+1};
    title(var_name_i, 'Interpreter', 'none'); grid on; xlabel('SOC');
end

linkaxes([ax], 'x')


%% Make sure OCV is strictly increasing & Export parameters
try
    validateattributes(param.OCV, {'double'}, {'nondecreasing'})
catch
    errorInd1 = [];
    for i = 2:height(param)
        if param.OCV(i) <= param.OCV(i-1)
            errorInd1 = [errorInd1; i];
        end
    end
    error("Check if param.OCV_init is strictly increasing (see errorInd1)")
end

% Validate OCV ub is greater than OCV lb 
OCVdiff = param.OCVMax - param.OCVMin; 
errorInd2 = find(OCVdiff<=0, 1); 
if ~isempty(errorInd2)
    error('Check ub & lb of OCV (see errorInd2)');
end

% Save parameters
settings.parameters.param = psObj.Parameters;
filename = settings.folders.result + "\Parameters_analytical_" + file + "_" + settings.ECM_info.order + "RC.mat"; 
save(filename, "settings", "psObj", "-mat")
