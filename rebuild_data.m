function out_data = rebuild_data(data)
% ����ά�������Ϊһά���ݣ����ڰ����������ų�һ����������ѵ�� arima ģ�͡�

out_data = [];
for i=1:1:size(data,1)
    out_data = [out_data , norm_change(data(i,:))];
end
