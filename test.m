% load some system
addpath('./simulink_models/Autonomous-Drive/ACC')
run('ACC_Script.m')
load_system('ACC')

% https://www.mathworks.com/matlabcentral/answers/478932-convert-struct-to-readable-json-pretty-print#answer_884815
% PrettyPrint option introduced in R2021a
j = jsonencode(simulink_dump('ACC'), 'PrettyPrint', true);

writelines(j, "test.json")