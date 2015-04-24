function prediction_sequence = implement_Wave_nerve(real_value,day_number,node_number,Wave_params)
% real_value    待预测的真实值
% node_number       输入神经网络输入层节点数量(结构体)
% Wave_params 小波神经网络模型参数

cut_result = data_cut(real_value,day_number,node_number.input);

% 读取节点值
M = node_number.input;
n = node_number.hidden;
N =  node_number.output;

% 读取模型参数
Wjk =Wave_params.Wjk ;
a =Wave_params.a;
b=Wave_params.b;
Wij= Wave_params.Wij ;
inputps= Wave_params.inputps ;
outputps = Wave_params.outputps;

%预测输入归一化
x=mapminmax('apply',cut_result.input,inputps);
x=x';
yuce=zeros(length(cut_result.input),1);
y=zeros(1,N);
net=zeros(1,n);
net_ab=zeros(1,n);
%网络预测
for i=1:length(cut_result.input)
    x_test=x(i,:);
    for j=1:1:n
        for k=1:1:M
            net(j)=net(j)+Wjk(j,k)*x_test(k);
            net_ab(j)=(net(j)-b(j))/a(j);
        end
        temp=mymorlet(net_ab(j));
        for k=1:N
            y(k)=y(k)+Wij(k,j)*temp ; 
        end
    end

    yuce(i)=y(k);
    y=zeros(1,N);
    net=zeros(1,n);
    net_ab=zeros(1,n);
end
%预测输出反归一化
prediction_sequence=mapminmax('reverse',yuce,outputps);
disp('预测完成一次');