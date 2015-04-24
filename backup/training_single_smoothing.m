function [ Single_params  ] = training_single_smoothing( train_data , precision )
% ���룺ѵ�����У�ɨ�辫�ȡ�
%  train_data , precision
% �������ָ��ƽ���㷨����
% Single_params

%ȫ�ֲ���
MSE_array = [];
MSE_errs = [];
W = 0;
Single_Out = zeros( 1,length(train_data) + 1 );
length_data = length(train_data);
%�� Single_Out ǰn��ֵ����ʼֵ
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
% ����ʹ�������Ϣ
% �ṹ��
% rmfield(example,'age')
% fieldnames(example)
% isfield(example,'age')
%~~~~~~~~~~~~~~~~~~%