%�������ڸı�һ��һά�����ķ���
function out_data = dimension_change(input_data , type)

[row , col ] = size(input_data);

if strcmp('row' , type)
    if (row == 1)
        out_data = input_data;
    else
        out_data = input_data';
    end
elseif strcmp('col' , type)
    if (row == 1)
        out_data = input_data';
    else
        out_data = input_data;
    end
end

end