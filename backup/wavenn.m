function wavenn(Force_train)
%% 清空环境变量
close all;
%% 网络参数配置
load traffic_flux input output input_test output_test

M=size(input,2); %输入节点个数
N=size(output,2); %输出节点个数

n=6; %隐形节点个数
lr1=0.01; %学习概率
lr2=0.001; %学习概率
maxgen=400; %迭代次数

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

%% 输入输出数据归一化
[inputn,inputps]=mapminmax(input');
[outputn,outputps]=mapminmax(output'); 
inputn=inputn';
outputn=outputn';

error=zeros(1,maxgen);
%% 网络训练
if ~Force_train

   load ('traffic_flux' , 'Wjk','a','b','Wij' ) ;
   disp(['使用保存模型预测' ]);

else
    i = 1;
    while (i <= maxgen) || ((i>1) && error(i-1) < 35)
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
            error(i)=error(i)+sum(abs(yqw-y));

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
    end    
    figure(6);
    plot(error);
end
%% 网络预测
%预测输入归一化
x=mapminmax('apply',input_test',inputps);
x=x';
yuce=zeros(92,1);
%网络预测
for i=1:92
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
ynn=mapminmax('reverse',yuce,outputps);

%保存模型
save('traffic_flux.mat', 'Wjk','a','b','Wij','input', 'output', 'input_test', 'output_test');

%取前三天均值，做均值线
line_data = zeros(1,96);
figure_1 = figure(1);
% line_color = ['r';'g';'b'];
temp_line = zeros(3,96);
for i=1:3
    temp_line(i,:) = [input([1+92*(i-1):92+92*(i-1)],1)' input(92*i,[2:4]) output(92*i,1)];
    line_data = line_data + temp_line(i,:);
%     plot(temp_line(i,:),line_color(i),'linewidth',2);hold on;
end
line_data = line_data/3;
line_data = line_data(5:96);

% 结果分析

figure_2 = figure(2);

plot(ynn,'r*:')
hold on
plot(line_data,'k','linewidth',2)
plot(output_test,'bo--')


title('预测 IP 流量','fontsize',12)
xlabel('时间点')
ylabel(' IP 流量')


figure_3 = figure(3);
subplot(3,2,[1 2]);
hist(ynn - output_test,[-100:4:100]);
title('横向预测误差的分布','fontsize',12)
subplot(3,2,[3 4]);
hist(line_data' - output_test,[-100:4:100]);
title('纵向误差的分布','fontsize',12)

% 首先获得前三天的误差曲线
% 预测输入归一化
x=mapminmax('apply',input',inputps);
x=x';
yuce=zeros(length(input),1);
% 网络预测
for i=1:length(input)
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
 pre_data =mapminmax('reverse',yuce,outputps);

 %误差
 deviation_x = [(pre_data - output)' , (ynn - output_test)'];
 deviation_y = [line_data - temp_line(1,[5:96]) ,line_data - temp_line(2,[5:96]) ,line_data - temp_line(3,[5:96]) ,(line_data' - output_test)'];
 
%误差预测计算单指数平滑算法参数
Single_params_x = training_single_smoothing( deviation_x , 0.01 );
Single_params_y = training_single_smoothing( deviation_y , 0.01 );

% 到此有 ynn （一天） 、 line_data （一天） 、 deviation_x （四天）、 deviation_y （四天） 

%用前三天计算 a 值 ， ect = a * ex + (1-a) * ey ;
deviation_x = dimension_change(deviation_x,'row');
deviation_y = dimension_change(deviation_y,'row');
value_a = [];
value_a = calculate_a(deviation_x , deviation_y);


% 计算 a 值的单指数平滑算法参数
 Single_params_a = training_single_smoothing( value_a(1,1:(end-length(output_test))) , 0.01 );   
%  Single_params_a.W = 0.4 ;
 disp(['Single_params_a: ' num2str(Single_params_a.W)]);
 % 用二维预测方法 预测流量值  pre_value = a * xt + (1-a) * yt 
 % 到此有 ynn （一天） 、 line_data （一天） 、 deviation_x （四天）、 deviation_y （四天）
 % 、output_test  真实值。

 % 方法一：对 a 使用单指数平滑,计算预测输出
pre_a = implement_Single(Single_params_a,value_a(1,end-length(output_test)+1:end));
prediction_value_a = pre_a.*ynn' + (1-pre_a).*line_data;
prediction_value_a(1,1) = output_test(1,1);

% 绘制使用的 a 值曲线
figure(figure_1);
plot(value_a(1,end-length(output_test)+1:end),'ko-','linewidth',1.5);
hold on;
plot(pre_a,'ro-','linewidth',1.5);


%补绘二维预测结果
figure(figure_2);
plot(prediction_value_a,'g*:');

%补绘二维预测误差分布
figure(figure_3);
subplot(3,2,5);
hist(prediction_value_a' - output_test,[-100:4:100]);
title('平滑 a 二维预测误差的分布','fontsize',12);
% 平滑 a 误差分析 MSE 和 方差
figure_4 = figure(4);
subplot(1,2,1);
MSE_VAR_array = [sum((ynn - output_test).^2)/length(ynn), sum((line_data' - output_test).^2)/length(line_data) , ...
    sum((prediction_value_a' - output_test).^2)/length(output_test); ...
    std(ynn - output_test).^2, std(line_data' - output_test).^2 ,std(prediction_value_a' - output_test).^2 ...
    ];
bar_hander = bar(MSE_VAR_array,'grouped');
legend(bar_hander,'横向预测','纵向预测','二维预测');
set(gca,'xticklabel' , {'MSE' ,'方差'},'fontsize' ,12);
title('平滑 a 预测误差的结果比较图 （左侧一组为 MSE ---- 右侧一组为方差）');
fprintf('MSE>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(1,:));
fprintf('方差>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(2,:));
%方法二：先求出下一时刻 ex 、 ey 的单指数平滑值，让后用预估的 ex 、 ey 计算 a 值
pre_ex = implement_Single(Single_params_x,deviation_x(1,end-length(output_test)+1:end));
pre_ey = implement_Single(Single_params_y,deviation_y(1,end-length(output_test)+1:end));
value_a = calculate_a(pre_ex,pre_ey);
prediction_ex_ey = value_a.*ynn' + (1-value_a).*line_data;
prediction_ex_ey(1,1) = output_test(1,1);
figure(figure_2);
plot(prediction_ex_ey,'m*:');
legend('横向预测' , '纵向预测' ,'真实值', '平滑 a 二维预测', '平滑 ex ey 二维预测');

figure(figure_1);
plot(value_a,'go-','linewidth',1.5);
legend('a 的真实值','平滑 a 使用的 a 值曲线' ,'平滑 ex ey 使用的 a 值曲线');
% 平滑 ex ey 误差分析 MSE 和 方差
figure(figure_4);
subplot(1,2,2);
bar_hander = bar([sum((ynn - output_test).^2)/length(ynn), sum((line_data' - output_test).^2)/length(line_data) , ...
    sum((prediction_ex_ey' - output_test).^2)/length(output_test); ...
    std(ynn - output_test).^2, std(line_data' - output_test).^2 ,std(prediction_ex_ey' - output_test).^2 ...
    ],'grouped');
legend(bar_hander,'横向预测','纵向预测','二维预测');
set(gca,'xticklabel' , {'MSE' ,'方差'},'fontsize' ,12);
title('平滑 ex ey 预测误差的结果比较图 （左侧一组为 MSE ---- 右侧一组为方差）');
%补绘二维预测误差分布
figure(figure_3);
subplot(3,2,6);
hist(prediction_ex_ey' - output_test,[-100:4:100]);
title('平滑 ex ey 二维预测误差的分布','fontsize',12);
