function main( Force_train,Force_ARIMA_train )
% 清空环境变量
close all;
% 网络参数配置
vertical_num_day  = 33;
horizontal_num_day = 3;
fluctuate = 0.02;

[ vertical_traffic_data , horizontal_traffic_data , new_data ] = data_producer( vertical_num_day , horizontal_num_day, fluctuate );
if Force_train && Force_ARIMA_train
    save('saved/producer_data.mat','vertical_traffic_data' , 'horizontal_traffic_data' , 'new_data');
else
    load('saved/producer_data.mat','vertical_traffic_data' , 'horizontal_traffic_data' , 'new_data');
end

M = 3; 
n = 4 ;
N = 1; 

% 显示垂直维度数据序列组
figure_7 = figure(7);
hold on;
for i=1:1:size(vertical_traffic_data,1)
    plot(vertical_traffic_data(:,i));
end
% 构造小波神经网络节点结构体
node_number.input = M;
node_number.hidden = n;
node_number.output = N;

% 训练神经网络

Wave_params = wave_nerve(horizontal_traffic_data ,horizontal_num_day, node_number ,Force_train);

input_out_data = data_cut(horizontal_traffic_data,horizontal_num_day,M);
output = input_out_data.output';
output_out_data = data_cut(new_data,1,M);
output_test = output_out_data.output';

% 训练 arima 模型
if Force_ARIMA_train
    Arima_params = train_arima( rebuild_data(detrend(vertical_traffic_data)));    
    disp(['ARIMA 使用新模型' ]);
else
   disp(['ARIMA 使用保存模型' ]);
end

% disp(Arima_params);
if Force_ARIMA_train
    line_data = zeros(1,length(new_data));
    for i=1:1:length(new_data)
        prediction_temp_data = [vertical_traffic_data(:,i)' new_data(1,i)];
        predicton_out = implement_arima( Arima_params , prediction_temp_data);
        line_data(1,i) = predicton_out(1,end);
        disp(['arima:' num2str(i) '次'  '误差：' num2str(line_data(1,i) - new_data(1,i))]);
    end

    line_data = line_data(1,node_number.input+1:end);

    pre_vertical_data = [];
    for i=1:1:horizontal_num_day
        temp_line = [];
        pre_new_data = vertical_traffic_data(size(vertical_traffic_data,1) - i +1,:);
        for j=1:1:length(pre_new_data)
            prediction_temp_data = vertical_traffic_data(1:(size(vertical_traffic_data,1) - i + 1 ),j)';
            predicton_out = implement_arima( Arima_params , prediction_temp_data);
            temp_line(1,j) = predicton_out(1,end);
            disp(['arima:' '第' num2str(i) '天' num2str(j) '次'  '误差：' num2str(temp_line(1,j) - pre_new_data(1,j))]);
        end   
        temp_line = temp_line(1,node_number.input+1:end);
        pre_vertical_data = [pre_vertical_data temp_line];
    end
    save('saved/ARIMA_params.mat', 'pre_vertical_data','line_data','Arima_params');
else
    load('saved/ARIMA_params.mat', 'pre_vertical_data','line_data','Arima_params');
end
% 使用神经网路预测
ynn = implement_Wave_nerve(new_data,1,node_number,Wave_params);

% 结果分析

figure_2 = figure(2);

plot(ynn,'r*-')
hold on
plot(line_data,'k','linewidth',2)
plot(output_test,'bo-')


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

 pre_horizontal_data =implement_Wave_nerve(horizontal_traffic_data,horizontal_num_day,node_number,Wave_params);

 
 %误差
 deviation_x = [(pre_horizontal_data - output)' , (ynn - output_test)'];
 deviation_y = [ (pre_vertical_data' - output)',(line_data' - output_test)'];

 
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
plot(prediction_value_a,'g*-');

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

% 命令窗口打印输出
fprintf('数据生成器参数: 波动率:%f 横向数据天数:%d 纵向数据天数:%d \n',fluctuate ,horizontal_num_day ,vertical_num_day  );
fprintf('小波神经网络参数: 输入节点数:%d 隐含层节点数:%d 输出节点数: %d\n',node_number.input , node_number.hidden , node_number.output);
fprintf('ARIMA 算法模型参数>> \n 差分次数d:%d AR 阶数 p:%d MA 阶数 q:%d\n',Arima_params.I,Arima_params.p,Arima_params.q);
fprintf('平滑 a 值使用的权值:%f\n',Single_params_a.W);
fprintf('MSE>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(1,:));
fprintf('方差>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(2,:));

%方法二：先求出下一时刻 ex 、 ey 的单指数平滑值，让后用预估的 ex 、 ey 计算 a 值
pre_ex = implement_Single(Single_params_x,deviation_x(1,end-length(output_test)+1:end));
pre_ey = implement_Single(Single_params_y,deviation_y(1,end-length(output_test)+1:end));
value_a = calculate_a(pre_ex,pre_ey);
prediction_ex_ey = value_a.*ynn' + (1-value_a).*line_data;
prediction_ex_ey(1,1) = output_test(1,1);
figure(figure_2);
plot(prediction_ex_ey,'m*-');
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
