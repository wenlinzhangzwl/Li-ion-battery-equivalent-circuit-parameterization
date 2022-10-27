function parameters_output = parameter_initialization(settings)
% Sets the initial guess & upper/lower bounds for ECM parameters
% Outputs parametes as struct

    ECM_order = settings.ECM_info.order;
    num_of_breakpoints = settings.parameters.num_of_breakpoints; 
    Vmax = settings.cell.Vmax; 
    Vmin = settings.cell.Vmin; 
    
    switch settings.cell.name
        case "EVE280"
            if ECM_order == 1
                % R0
                parameters_output.R0 = 1e-3 * ones(1, num_of_breakpoints); 
                parameters_output.R0Min = 1e-6 * ones(1, num_of_breakpoints); 
                parameters_output.R0Max = 0.1 * ones(1, num_of_breakpoints); 
                % R1
                parameters_output.Rx(1, :) = 1e-3 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(1, :) = 1e-6 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(1, :) = 0.1 * ones(1, num_of_breakpoints); 
                % OCV
                parameters_output.Em = (Vmax+Vmin)/2 * ones(1, num_of_breakpoints);
                parameters_output.EmMin = Vmin * ones(1, num_of_breakpoints);
                parameters_output.EmMax = Vmax * ones(1, num_of_breakpoints);
                % T1
                parameters_output.Tx(1, :) = 1 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(1, :) = 0.1 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(1, :) = 50 * ones(1, num_of_breakpoints);
            elseif ECM_order == 2
                % R0
                parameters_output.R0 = 1e-4 * ones(1, num_of_breakpoints); 
                parameters_output.R0Min = 1e-6 * ones(1, num_of_breakpoints); 
                parameters_output.R0Max = 0.1 * ones(1, num_of_breakpoints); 
                % R1
                parameters_output.Rx(1, :) = 1e-4 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(1, :) = 1e-6 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(1, :) = 0.1 * ones(1, num_of_breakpoints); 
                % R2
                parameters_output.Rx(2, :) = 1e-4 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(2, :) = 1e-6 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(2, :) = 0.1 * ones(1, num_of_breakpoints); 
                % OCV
                parameters_output.Em = (Vmax+Vmin)/2 * ones(1, num_of_breakpoints);
                parameters_output.EmMin = Vmin * ones(1, num_of_breakpoints);
                parameters_output.EmMax = Vmax * ones(1, num_of_breakpoints);
                % T1
                parameters_output.Tx(1, :) = 1 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(1, :) = 1 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(1, :) = 20 * ones(1, num_of_breakpoints);
                % T2
                parameters_output.Tx(2, :) = 100 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(2, :) = 50 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(2, :) = 1000 * ones(1, num_of_breakpoints);

            elseif ECM_order == 3
%                 % R0
%                 parameters_output.R0 = 1e-4 * ones(1, num_of_breakpoints); 
%                 parameters_output.R0Min = 1e-5 * ones(1, num_of_breakpoints); 
%                 parameters_output.R0Max = 1e-3 * ones(1, num_of_breakpoints); 
%                 % R1
%                 parameters_output.Rx(1, :) = 1e-4 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMin(1, :) = 1e-5 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMax(1, :) = 1e-3 * ones(1, num_of_breakpoints); 
%                 % R2
%                 parameters_output.Rx(2, :) = 1e-4 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMin(2, :) = 1e-5 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMax(2, :) = 1e-3 * ones(1, num_of_breakpoints); 
%                 % R3
%                 parameters_output.Rx(3, :) = 1e-4 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMin(3, :) = 1e-5 * ones(1, num_of_breakpoints); 
%                 parameters_output.RxMax(3, :) = 1e-3 * ones(1, num_of_breakpoints); 
%                 % OCV
%                 parameters_output.Em = (Vmax+Vmin)/2 * ones(1, num_of_breakpoints);
%                 parameters_output.EmMin = Vmin * ones(1, num_of_breakpoints);
%                 parameters_output.EmMax = Vmax * ones(1, num_of_breakpoints);
%                 % T1
%                 parameters_output.Tx(1, :) = 1 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMin(1, :) = 0.1 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMax(1, :) = 50 * ones(1, num_of_breakpoints);
%                 % T2
%                 parameters_output.Tx(2, :) = 100 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMin(2, :) = 100 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMax(2, :) = 200 * ones(1, num_of_breakpoints);
%                 % T3
%                 parameters_output.Tx(3, :) = 1000 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMin(3, :) = 500 * ones(1, num_of_breakpoints);
%                 parameters_output.TxMax(3, :) = 3000 * ones(1, num_of_breakpoints);

                % R0
                parameters_output.R0 = 2e-4 * ones(1, num_of_breakpoints); 
                parameters_output.R0Min = 1e-5 * ones(1, num_of_breakpoints); 
                parameters_output.R0Max = 1e-3 * ones(1, num_of_breakpoints); 
                % R1
                parameters_output.Rx(1, :) = 2e-4 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(1, :) = 1e-5 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(1, :) = 1e-3 * ones(1, num_of_breakpoints); 
                % R2
                parameters_output.Rx(2, :) = 2e-4 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(2, :) = 1e-5 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(2, :) = 1e-3 * ones(1, num_of_breakpoints); 
                % R3
                parameters_output.Rx(3, :) = 2e-4 * ones(1, num_of_breakpoints); 
                parameters_output.RxMin(3, :) = 1e-5 * ones(1, num_of_breakpoints); 
                parameters_output.RxMax(3, :) = 1e-3 * ones(1, num_of_breakpoints); 
                % OCV
                parameters_output.Em = (Vmax+Vmin)/2 * ones(1, num_of_breakpoints);
                parameters_output.EmMin = Vmin * ones(1, num_of_breakpoints);
                parameters_output.EmMax = Vmax * ones(1, num_of_breakpoints);
                % T1
                parameters_output.Tx(1, :) = 2 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(1, :) = 1 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(1, :) = 10 * ones(1, num_of_breakpoints);
                % T2
                parameters_output.Tx(2, :) = 50 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(2, :) = 20 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(2, :) = 80 * ones(1, num_of_breakpoints);
                % T3
                parameters_output.Tx(3, :) = 1000 * ones(1, num_of_breakpoints);
                parameters_output.TxMin(3, :) = 500 * ones(1, num_of_breakpoints);
                parameters_output.TxMax(3, :) = 1800 * ones(1, num_of_breakpoints);
            end
    end

end

