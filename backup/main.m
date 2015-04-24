function main( Force_train )
% 清空环境变量
close all;
% 网络参数配置
load traffic_flux input output input_test output_test;

M = 3; N = 1; n = 4; 

% 构造小波神经网络节点结构体
node_number.input = M;
node_number.hidden = n;
node_number.output = N;

day_number = 3 ;

% 数据重建为一维数据
line_data = zeros(1,96);
temp_line = zeros(day_number,96);
for i=1:day_number
    temp_line(i,:) = [input([1+92*(i-1):92+92*(i-1)],1)' input(92*i,[2:4]) output(92*i,1)];
    line_data = line_data + temp_line(i,:);
end
line_data = line_data/day_number;
line_data = line_data(M+1:96);

temp = zeros(1,96);
temp(1,:) = [input_test([1:92],1)' input_test(92,[2:4]) output_test(92,1)];

% 训练神经网络
input_sequence = [temp_line(1,:) temp_line(2,:) temp_line(3,:)];
Wave_params = wave_nerve(input_sequence ,day_number, node_number ,Force_train);

input_out_data = data_cut(input_sequence,day_number,M);
output = input_out_data.output';
output_out_data = data_cut(temp,1,M);
output_test = output_out_data.output';
% 使用神经网路预测
ynn = implement_Wave_nerve(temp(1,:),1,node_number,Wave_params);

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

 pre_data =implement_Wave_nerve(input_sequence,day_number,node_number,Wave_params);

 %误差
 deviation_x = [(pre_data - output)' , (ynn - output_test)'];
 deviation_y = [line_data - temp_line(1,[M+1:96]) ,line_data - temp_line(2,[M+1:96]) ,line_data - temp_line(3,[M+1:96]) ,(line_data' - output_test)'];
 
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
 disp(node_number);
 disp(['Single_params_a: ' num2str(Single_params_a.W)]);
 % 用二维预测方法 预测流量值  pre_value = a * xt + (1-a) * yt 
 % 到此有 ynn （一天） 、 line_data （一天） 、 deviation_x （四天）、 deviation_y （四天）
 % 、output_test  真实值。

 % 方法一：对 a 使用单指数平滑,计算预测输出
pre_a = implement_Single(Single_params_a,value_a(1,end-length(output_test)+1:end));
prediction_value_a = pre_a.*ynn' + (1-pre_a).*line_data;
prediction_value_a(1,1) = output_test(1,1);

% 绘制使用的 a 值曲线
figure_1 = figure(1);
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
