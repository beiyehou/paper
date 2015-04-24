function [ Single_params  ] = training_single_smoothing( train_data , precision )
% 输入：训练序列，扫描精度。
%  train_data , precision
% 输出：单指数平滑算法参数
% Single_params

%全局参量
MSE_array = [];
MSE_errs = [];
W = 0;
Single_Out = zeros( 1,length(train_data) + 1 );
length_data = length(train_data);
%给 Single_Out 前n个值赋初始值
Single_Out(1,2) = train_data(1,1);
errs_index = 0;
while (W<1)
   for i=3:length_data
       Single_Out(1,i) = W * train_data(1,i-1) + (1-W) * Single_Out(1,i-1);
   end
   MSE_array = Single_Out(1,2:length_data)-train_data(1,2:length_data);
   errs_index = errs_index + 1;
   MSE_errs(1,errs_index) = MSE_array*MSE_array';
   MSE_errs(2,errs_index) = W;
   W = W + precision;
end

[Single_params.value , Single_params.index]= min(MSE_errs(1,:));
Single_params.W = MSE_errs(2,Single_params.index);

% plot(MSE_errs(2,:),MSE_errs(1,:));

end

%~~~~~~~~~~~%
% 程序使用相关信息
% 结构体
% rmfield(example,'age')
% fieldnames(example)
% isfield(example,'age')
%~~~~~~~~~~~~~~~~~~%