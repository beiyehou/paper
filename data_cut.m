function out_data = data_cut(input_sequence,day_number,M)
% 把一维数据剪切为 M + 1 行数据
% input_sequence    输入数据
% M     决定输入数据分成几行
% node_number 节点数量
% out_data      分好之后的数据

input = zeros(M,day_number * (length(input_sequence)/day_number-M));
output = zeros(1,size(input,2));
input_sequence = dimension_change(input_sequence,'row');
for day = 1:day_number
    new_day = input_sequence(1,(day-1)*length(input_sequence)/day_number+1:day*length(input_sequence)/day_number);
    for index = 1:M
        input(index,1+(day-1) * (length(new_day)-M):day * (length(new_day)-M)) = new_day(1,index:(length(new_day)-M+index-1));
    end
    index = index + 1;
    output(1+(day-1) *( length(new_day) - M):day * (length(new_day)-M)) = new_day(1,index:(length(new_day)-M+index-1));
end
out_data.input = input;
out_data.output = output;