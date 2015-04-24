% ���������ڸ��������� a ��ֵ
function out_a = calculate_a(ex,ey)

if length(ex) ~= length(ey)
    error('function calculate:ex ey must be the same size');
end

value_a = [];
for i=1:length(ex)
    if ex(1,i) * ey < 0
        value_a(1,i) = ey(1,i)/(ey(1,i) - ex(1,i));
    else
        if abs(ex(1,i)) < abs(ey(1,i)) 
            value_a(1,i) = 1;
        else
            value_a(1,i) = 0;
        end
    end
end
out_a = value_a; 
end