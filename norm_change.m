function [ output_args ] = norm_change( input_args )
% 此函数用于将数组归一化到 [0,1] 区间中 out = (x-min)/(max-min)
% 用于函数 out_data = rebuild_data(data)；
min_value = min(input_args);
max_value = max(input_args);
output_args = (input_args-min_value)/(max_value-min_value);
end

