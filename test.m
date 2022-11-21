addpath("deps_matlab/jsonlab")

% load some system
addpath("./simulink_models/Autonomous-Drive/ACC")
run("ACC_Script.m")
load_system("ACC")

tic()
% extract Simulink information
obj = simulink_dump("ACC");
toc()

% https://www.mathworks.com/matlabcentral/answers/478932-convert-struct-to-readable-json-pretty-print#answer_884815
% PrettyPrint option introduced in R2021a
%%j = jsonencode(obj, 'PrettyPrint', true);
%%writelines(j, "test.json")

% filename must be char: https://github.com/fangq/jsonlab/issues/84
rootname = '';
tic()
savejson(rootname, obj, 'test.json')
toc()
