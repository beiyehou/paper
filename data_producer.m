function [ vertical_traffic_data , horizontal_traffic_data , new_data ] = data_producer( vertical_num_day , horizontal_num_day, fluctuate,deta )
% �ɻ��ƺõ�����Ϊģ�壬���� num_day �����������
% num_day                           �������ݱ�ʾ���������������
% fluctuate                            �������ݱ�ʾ������Դ�С
% vertical_traffic_data         ������ݣ�Ϊ��ֱά�ȵĶ�ά���� (num_day , 24*60/5)
% horizontal_traffic_data     ������ݣ�Ϊ����ά�ȵ�һά���� (1,num_day*24*60/5)
% new_data                          ������ݣ�Ϊһ��Ĳ�������

load( 'saved/preducer.mat', 'traffic_data');
% deta = 1;
model_data = traffic_data;
model_data = dimension_change(model_data,'row');
model_producer = zeros(vertical_num_day , length(model_data));

for i = 1: 1 : vertical_num_day
    rand_index = randperm(length(model_data),length(model_data)/deta);
    model_producer(i,:) = model_data;
    model_producer(i,rand_index) = model_data(rand_index) .* (1+rand(1,length(rand_index))*fluctuate*2 - fluctuate);
end

horizontal_data = zeros(1,length(model_data)*horizontal_num_day);
for j =1:1:horizontal_num_day
    horizontal_data(1,(j-1)*length(model_data)+1:j*length(model_data)) = model_producer(horizontal_num_day-(j-1),:);
end

horizontal_traffic_data = horizontal_data;
vertical_traffic_data = model_producer(size(model_producer,1):-1:1,:);
rand_index = randperm(length(model_data),length(model_data)/deta);
new_data = model_data;
new_data(rand_index) = model_data(rand_index) .* (1+rand(1,length(rand_index))*fluctuate*2 - fluctuate);

end

