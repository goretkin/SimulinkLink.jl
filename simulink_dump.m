function out = simulink_dump(sys)
%SIMULINK_DUMP Summary of this function goes here
%   Detailed explanation goes here
    handles = find_system(gcs, 'FindAll', 'on');

    objs = arrayfun(@(h) simulink_dump_shallow(h), handles)
    out = objs
end

