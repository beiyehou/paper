function   Wave_params = wave_nerve(input_sequence ,day_number, node_number ,Force_train)
% input_sequence    输入数据序列
% node_number       输入神经网络输入层节点数量(结构体)
% day_number          输入数据序列可分为几天
% Force_train           输入提示是否强制训练网路 为 1 训练 为 0 使用保存模型
% Wave_params      输出神经网络参数(结构体)

% 初始化参数
M = node_number.input;             %输入节点个数
N = node_number.output;           %输出节点个数
n = node_number.hidden;           %隐形节点个数

lr1=0.01;                   %学习概率
lr2=0.001;                 %学习概率
maxgen=500;           %迭代次数

%权值初始化
Wjk=randn(n,M);Wjk_1=Wjk;Wjk_2=Wjk_1;
Wij=randn(N,n);Wij_1=Wij;Wij_2=Wij_1;
a=randn(1,n);a_1=a;a_2=a_1;
b=randn(1,n);b_1=b;b_2=b_1;

%节点初始化
y=zeros(1,N);
net=zeros(1,n);
net_ab=zeros(1,n);

%权值学习增量初始化
d_Wjk=zeros(n,M);
d_Wij=zeros(N,n);
d_a=zeros(1,n);
d_b=zeros(1,n);

% 处理输入序列
input = [];
output = [];
input_sequence = dimension_change(input_sequence,'row');
cut_result = data_cut(input_sequence,day_number,M);


input = cut_result.input';
output = cut_result.output';

% 输入输出数据归一化
[inputn,inputps]=mapminmax(input');
[outputn,outputps]=mapminmax(output'); 
inputn=inputn';
outputn=outputn';

% 网络训练
error=zeros(1,maxgen);

if ~Force_train
   load ('saved/Wave_params.mat' , 'Wjk','a','b','Wij' ,'inputps','outputps') ;
   disp(['小波使用保存模型' ]);
else
    disp(['小波使用新的模型']);
    i = 1;
    while (i <= maxgen) 
%         if ((i>1) && error(i-1) < 39)
%             break;
%         end
        %误差累计
        error(i)=0;
        % 循环训练
        for kk=1:size(input,1)
            x=inputn(kk,:);
            yqw=outputn(kk,:);

            for j=1:n
                for k=1:M
                    net(j)=net(j)+Wjk(j,k)*x(k);
                    net_ab(j)=(net(j)-b(j))/a(j);
                end
                temp=mymorlet(net_ab(j));
                for k=1:N
                    y=y+Wij(k,j)*temp;   %小波函数
                end
            end

            %计算误差和
            error(i)=error(i)+sum((yqw-y).^2)/length(yqw);
%             error(i) = error(i) + std(yqw-y).^2;

            %权值调整
            for j=1:n
                %计算d_Wij
                temp=mymorlet(net_ab(j));
                for k=1:N
                    d_Wij(k,j)=d_Wij(k,j)-(yqw(k)-y(k))*temp;
                end
                %计算d_Wjk
                temp=d_mymorlet(net_ab(j));
                for k=1:M
                    for l=1:N
                        d_Wjk(j,k)=d_Wjk(j,k)+(yqw(l)-y(l))*Wij(l,j) ;
                    end
                    d_Wjk(j,k)=-d_Wjk(j,k)*temp*x(k)/a(j);
                end
                %计算d_b
                for k=1:N
                    d_b(j)=d_b(j)+(yqw(k)-y(k))*Wij(k,j);
                end
                d_b(j)=d_b(j)*temp/a(j);
                %计算d_a
                for k=1:N
                    d_a(j)=d_a(j)+(yqw(k)-y(k))*Wij(k,j);
                end
                d_a(j)=d_a(j)*temp*((net(j)-b(j))/b(j))/a(j);
            end

            %权值参数更新      
            Wij=Wij-lr1*d_Wij;
            Wjk=Wjk-lr1*d_Wjk;
            b=b-lr2*d_b;
            a=a-lr2*d_a;

            d_Wjk=zeros(n,M);
            d_Wij=zeros(N,n);
            d_a=zeros(1,n);
            d_b=zeros(1,n);

            y=zeros(1,N);
            net=zeros(1,n);
            net_ab=zeros(1,n);

            Wjk_1=Wjk;Wjk_2=Wjk_1;
            Wij_1=Wij;Wij_2=Wij_1;
            a_1=a;a_2=a_1;
            b_1=b;b_2=b_1;
        end
        i = i + 1;
        disp(['训练完成：' num2str(i) '次']);
    end
    %保存模型
    figure(6);plot(error);
    save('saved/Wave_params.mat', 'Wjk','a','b','Wij','inputps','outputps');
end

Wave_params.Wjk = Wjk;
Wave_params.a = a;
Wave_params.b = b;
Wave_params.Wij = Wij;
Wave_params.inputps = inputps;
Wave_params.outputps = outputps;



