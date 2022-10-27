function obj = parameterization_Objective(settings, optObj_current, optObj_prev, param_opt)

    % Convert parameters into form compatiable with battery model
    param_opt = format_opt_param(param_opt, settings.ECM_info.order, "vector2table");
    param_opt.SOC = optObj_current.SOC;
    if isempty(optObj_prev)
        parameters = param_opt; 
    else
        parameters = [optObj_prev.param_after_table; param_opt];
    end

    % Run model
    current_dmd = optObj_current.segment.Current; 
    capacity_Ah = settings.cell.capacity_Ah_actual;
    [Vt, ~, ~] = settings.optim.batt_model(settings, current_dmd, optObj_current.initStates, parameters, capacity_Ah); 

    % Calculate objective function
    error_Vt = abs(optObj_current.segment.Voltage - Vt); 

%     % Plotting measured & simulated Vt
%     figure; hold on
%     plot(optObj_current.segment.Time, optObj_current.segment.Voltage, '.-')
%     plot(optObj_current.segment.Time, Vt, '.-')
%     legend("true", "sim"); grid on
    
    if settings.optim.method == "LS" % Return vector obj function
        obj = error_Vt; 
    else % Return scalar obj function
        
%         if dataType == "pulse"
%             % Weight dynamic & rest portions proportional to the # of data points
% 
%             max_current = max(abs(optObj.segment.Current));
%             threshold = max_current * 0.1;
% 
%             indDyn = find(abs(optObj.segment.Current) > threshold);
%             indRest = find(abs(optObj.segment.Current) <= threshold);
% 
%             numDyn = height(indDyn);
%             numRest = height(indRest);
%             ratio = numRest/numDyn; 
% 
%             error_Vt(indDyn) = error_Vt(indDyn) * ratio; 
%         end

        obj = sum(error_Vt.^2);
    end
    
end

