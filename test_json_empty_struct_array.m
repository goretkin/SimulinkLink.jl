addpath("deps_matlab/jsonlab")

empty_struct = repmat(struct('a', 1, 'b', 2), 0, 2);

savejson('', empty_struct, 'test.json')
