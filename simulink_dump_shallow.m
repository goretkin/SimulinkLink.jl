function the_struct = simulink_dump_shallow(simulink_object)
%SIMULINK_DUMP_SHALLOW Summary of this function goes here
%   Detailed explanation goes here

    % https://www.mathworks.com/help/simulink/slref/common-block-parameters.html

    object_parameters = get_param(simulink_object, 'ObjectParameters');

    % n-by-1
    object_parameter_names = fieldnames(object_parameters);

    % for loops iterate through columns, make it 1-by-n
    object_parameter_names_iter = object_parameter_names';

    struct_build = struct.empty;

    for parameter_name_ = object_parameter_names_iter
        parameter_name = parameter_name_{1};

        if ismember('write-only', object_parameters.(parameter_name).Attributes)
            continue
        end

        struct_build(1).(parameter_name) = get_param(simulink_object, parameter_name);
        % why `(1)`? to avoid
        % A dot name structure assignment is illegal when the structure is empty.  Use a subscript on the structure.
    end
    the_struct = struct(...
        "getfullname", getfullname(simulink_object),...
        "ObjectParameters", object_parameters,...
        "get_param", struct_build...
    );
end

