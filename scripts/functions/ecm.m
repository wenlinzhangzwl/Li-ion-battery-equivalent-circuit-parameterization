function [Vt_output, SOC, endStates] = ecm(settings, current_dmd, initStates, parameters, capacity_Ah)
% xRC battery model

    Q = capacity_Ah * 3600; 
    deltaT = settings.data.deltaT;
    ECM_order = settings.ECM_info.order; 
    
    % Calculate SOC
    SOC_discharged = current_dmd * deltaT/Q; 
    SOC = initStates.SOC * ones(height(current_dmd), 1) - cumsum(SOC_discharged); 

    %% Calculate parameters at each time step
    % SOC breakpoints
    SOC_max = max(parameters.SOC);
    SOC_min = min(parameters.SOC); 
    SOC_interp = max(SOC_min, min(SOC, SOC_max));
    
    % OCV
    OCV = interp1(parameters.SOC, parameters.Em, SOC_interp, 'linear'); 
    
    % R0
    R0 = interp1(parameters.SOC, parameters.R0, SOC_interp, 'linear'); 

    % Rx & Tx
    R = zeros(height(current_dmd), ECM_order);
    var_names = string(parameters.Properties.VariableNames);
    for i = 1:ECM_order
        if ECM_order == 1
            parameters_Rx_i = table2array(parameters(:, var_names == "Rx")); 
            parameters_Tx_i = table2array(parameters(:, var_names == "Tx"));
        elseif ECM_order > 1
            parameters_Rx_i = table2array(parameters(:, var_names == "Rx_" + string(i))); 
            parameters_Tx_i = table2array(parameters(:, var_names == "Tx_" + string(i)));
        end
        Rx_i = interp1(parameters.SOC, parameters_Rx_i, SOC_interp, 'linear'); 
        Tx_i = interp1(parameters.SOC, parameters_Tx_i, SOC_interp, 'linear');
        R(:, i) = Rx_i;
        T(:, i) = Tx_i;
    end

%     figure;
%     time = 1:height(current_dmd); 
%     plot(time, current_dmd); grid on
    
    %% Initial states
    
%     Vt = zeros(height(current_dmd), 1); 
%     Vt(1) = initStates.Vt;

    I_RC = zeros(height(current_dmd), ECM_order);
    I_RC(1, :) = initStates.I_RC;

    V_nRC = zeros(height(current_dmd), ECM_order);
    V_nRC(1, :) = [I_RC(1, 1)*R(1, 1), I_RC(1, 2)*R(1, 2), I_RC(1, 3)*R(1, 3)];

    V = zeros(height(current_dmd), 3);  % V = [Vt, V_R0, V_RC]
    Vt_1 = initStates.Vt;
    V_R0_1 = current_dmd(1)*R0(1);
    V_RC_1 = sum(V_nRC(1, :), 'all');
    V(1, :) = [Vt_1, V_R0_1, V_RC_1];


    %% Calculate voltage at each time step
    for i = 2:height(current_dmd)

        % R0
        V_R0 = R0(i)*current_dmd(i); 

        % RC circuits
        I_RC(i, :) = (1 - exp(-deltaT./T(i, :))).* current_dmd(i) + exp(-deltaT./T(i, :)) .* I_RC(i-1, :);
        V_nRC(i, :) = I_RC(i, :) .* R(i, :);
        V_RC = sum(V_nRC(i, :), 'all');

        Vt = OCV(i) - V_R0 - V_RC; 

        V(i, :) = [Vt, V_R0, V_RC]; 
    end
    
    endStates.I_RC = I_RC(end, :);
    endStates.Vt = Vt;
    endStates.SOC = SOC(end);

    errInd = find(isinf(Vt), 1); 
    if ~isempty(errInd)
        error("Check errInd")
    end
    
    Vt_output = V(:, 1); 

%     figure; hold on;
%     time = 1:height(SOC); 
%     time = time/10; 
%     ax(1) = subplot(6, 1, 1); plot(time, V(:, 1), '.-'); grid on; ylabel('Vt [V]')
%     ax(2) = subplot(6, 1, 2); plot(time, OCV, '.-'); grid on; ylabel('OCV [V]')
%     ax(3) = subplot(6, 1, 3); plot(time, V(:, 2), '.-'); grid on; ylabel('V R0 [V]')
%     ax(4) = subplot(6, 1, 4); plot(time, V_nRC(:, 1), '.-'); grid on; ylabel('V RC1 [V]')
%     ax(5) = subplot(6, 1, 5); plot(time, V_nRC(:, 2), '.-'); grid on; ylabel('V RC2 [V]')
%     ax(6) = subplot(6, 1, 6); plot(time, V_nRC(:, 3), '.-'); grid on; ylabel('V RC3 [V]')
%     linkaxes(ax, 'x')
%     grid on; xlabel('Time [s]');
end

