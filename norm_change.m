function [ output_args ] = norm_change( input_args )
% �˺������ڽ������һ���� [0,1] ������ out = (x-min)/(max-min)
% ���ں��� out_data = rebuild_data(data)��
min_value = min(input_args);
max_value = max(input_args);
output_args = (input_args-min_value)/(max_value-min_value);
end

