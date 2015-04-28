function [ pre_a ] = implement_Single( Single_param_a , input_a ,Single_param_p)
% �Ը���������ʵʩ��ָ��ƽ���㷨
% Single_param_a ƽ��ָ���㷨�Ĳ��� �� input_a ��������
if length(input_a) < 3
    error('input sequence must longer than 2');
end
input_a = dimension_change(input_a,'row');
S = zeros(1,length(input_a));
S(2) = input_a(1,1);

for i=3:length(S)
    S(i) =  Single_param_a.W * input_a(1,i-1) + (1-Single_param_a.W) * S(i-1);
end
pre_a = S;
end
% if length(input_a) < 3
%     error('input sequence must longer than 2');
% end
% input_a = dimension_change(input_a,'row');
% S = zeros(1,length(input_a));
% 
% for i=1:1:Single_param_p
%     S(i) = input_a(1,i);
% end
% for i=(Single_param_p+1):1:length(S)
%     temp_S = input_a(1,i-Single_param_p);
%     for j = Single_param_p:-1:2
%         temp_S =  Single_param_a.W * input_a(1,i-j+1) + (1-Single_param_a.W) * temp_S;
%     end
%     S(i) = temp_S;
% end
% pre_a = S;
% end
