function out_data = rebuild_data(data)
% 将二维数据组合为一维数据，用于把纵向序列排成一个数列用于训练 arima 模型、

out_data = [];
for i=1:1:size(data,1)
    out_data = [out_data , norm_change(data(i,:))];
end
