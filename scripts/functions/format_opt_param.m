function parameters = format_opt_param(input_parameters, ECM_order, operation_type)
% Convert the input parameters from one format to another

    switch operation_type
        case "vector2table"
            if height(input_parameters) ~= 1
                input_parameters = input_parameters'; 
            end
            
            if length(input_parameters) == 2 + 2 * ECM_order
                if ECM_order == 1
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3)];
                    parameters.Tx = [input_parameters(4)];
                elseif ECM_order == 2
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3:4)];
                    parameters.Tx = [input_parameters(5:6)];
                elseif ECM_order == 3
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3:5)];
                    parameters.Tx = [input_parameters(6:8)];
                end  
            else
                if ECM_order == 1
                    parameters.Em = [input_parameters(1); input_parameters(5)];
                    parameters.R0 = [input_parameters(2); input_parameters(6)];
                    parameters.Rx = [input_parameters(3); input_parameters(7)];
                    parameters.Tx = [input_parameters(4); input_parameters(8)];
                elseif ECM_order == 2
                    parameters.Em = [input_parameters(1); input_parameters(7)];
                    parameters.R0 = [input_parameters(2); input_parameters(8)];
                    parameters.Rx = [input_parameters(3:4); input_parameters(9:10)];
                    parameters.Tx = [input_parameters(5:6); input_parameters(11:12)];
                elseif ECM_order == 3
                    parameters.Em = [input_parameters(1); input_parameters(9)];
                    parameters.R0 = [input_parameters(2); input_parameters(10)];
                    parameters.Rx = [input_parameters(3:5); input_parameters(11:13)];
                    parameters.Tx = [input_parameters(6:8); input_parameters(14:16)];
                end  
            end
            parameters = splitvars(struct2table(parameters));
        case "struct2table"
            fnames = fieldnames(input_parameters); 
            for i = 1:height(fnames)
                input_parameters.(fnames{i}) = transpose(input_parameters.(fnames{i}));
            end
            parameters = splitvars(struct2table(input_parameters));
        case "vector2struct"
            if height(input_parameters) ~= 1
                input_parameters = input_parameters'; 
            end

            if length(input_parameters) == 2 + 2 * ECM_order % two sets of parameters
                if ECM_order == 1
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3)];
                    parameters.Tx = [input_parameters(4)];
                elseif ECM_order == 2
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3:4)];
                    parameters.Tx = [input_parameters(5:6)];
                elseif ECM_order == 3
                    parameters.Em = [input_parameters(1)];
                    parameters.R0 = [input_parameters(2)];
                    parameters.Rx = [input_parameters(3:5)];
                    parameters.Tx = [input_parameters(6:8)];
                end  
            else % one set of parameters
                if ECM_order == 1
                    parameters.Em = [input_parameters(1); input_parameters(5)];
                    parameters.R0 = [input_parameters(2); input_parameters(6)];
                    parameters.Rx = [input_parameters(3); input_parameters(7)];
                    parameters.Tx = [input_parameters(4); input_parameters(8)];
                elseif ECM_order == 2
                    parameters.Em = [input_parameters(1); input_parameters(7)];
                    parameters.R0 = [input_parameters(2); input_parameters(8)];
                    parameters.Rx = [input_parameters(3:4); input_parameters(9:10)];
                    parameters.Tx = [input_parameters(5:6); input_parameters(11:12)];
                elseif ECM_order == 3
                    parameters.Em = [input_parameters(1); input_parameters(9)];
                    parameters.R0 = [input_parameters(2); input_parameters(10)];
                    parameters.Rx = [input_parameters(3:5); input_parameters(11:13)];
                    parameters.Tx = [input_parameters(6:8); input_parameters(14:16)];
                end  
            end
    
        case "param2table"
            fnames = fieldnames(input_parameters); 
            for i = 4:height(fnames)
                parameters.(fnames{i}) = transpose(input_parameters.(fnames{i}));
            end
            parameters = splitvars(struct2table(parameters));
    end
end