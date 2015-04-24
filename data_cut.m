function out_data = data_cut(input_sequence,day_number,M)
% ��һά���ݼ���Ϊ M + 1 ������
% input_sequence    ��������
% M     �����������ݷֳɼ���
% node_number �ڵ�����
% out_data      �ֺ�֮�������

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