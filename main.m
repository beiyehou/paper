function main( Force_train,Force_ARIMA_train )
% 清空环境变量
close all;
% 网络参数配置
vertical_num_day  = 0;
horizontal_num_day = 4;
fluctuate = 0.02;
deta = 1;

if Force_train && Force_ARIMA_train
%     [ vertical_traffic_data , horizontal_traffic_data , new_data ] = data_producer( vertical_num_day , horizontal_num_day, fluctuate ,deta );
    load('saved/preducer.mat','man_data');
    vertical_num_day = size(man_data,1) - 1;
    vertical_traffic_data = man_data(1:(size(man_data,1)-1),:);
    new_data = man_data(size(man_data,1),:);
    horizontal_traffic_data = [];
    for i = horizontal_num_day:-1:1
        horizontal_traffic_data = [horizontal_traffic_data man_data(size(man_data,1)-i,:)];
    end
    save('saved/producer_data.mat','vertical_traffic_data' , 'horizontal_traffic_data' , 'new_data');
else
    load('saved/producer_data.mat','vertical_traffic_data' , 'horizontal_traffic_data' , 'new_data');
    vertical_num_day = size(vertical_traffic_data,1);
end

M = 3; 
n = 4 ;
N = 1; 

% 显示垂直维度数据序列组
% figure_7 = figure(7);
% plot(vertical_traffic_data');

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

% 训练 ARIMA 模型
if Force_ARIMA_train
    Arima_params = train_arima( rebuild_data(detrend(vertical_traffic_data)));    
    disp(['ARIMA 使用新模型' ]);
else
   disp(['ARIMA 使用保存模型' ]);
end

% 使用 ARIMA 模型
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
% 使用神经网路预测新一天的数据
ynn = implement_Wave_nerve(new_data,1,node_number,Wave_params);

% 首先获得前 horizontal_num_day 天的预测曲线
 pre_horizontal_data =implement_Wave_nerve(horizontal_traffic_data,horizontal_num_day,node_number,Wave_params);

 % 前 horizontal_num_day 的误差
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
%  Single_params_a.W = 0.1 ;

 % 用二维预测方法 预测流量值  pre_value = a * xt + (1-a) * yt 

 % 方法一：对 a 使用单指数平滑,计算预测输出
pre_a = implement_Single(Single_params_a,value_a(1,end-length(output_test)+1:end),node_number.input);
prediction_value_a = pre_a.*ynn' + (1-pre_a).*line_data;
prediction_value_a(1,1) = output_test(1,1);

% 绘制使用的 a 值曲线
% figure_1 = figure(1);
% plot(value_a(1,end-length(output_test)+1:end),'ko-','linewidth',1.5);
% hold on;
% plot(pre_a,'ro-','linewidth',1.5);


%补绘二维预测结果
figure_2 = figure(2);
% 结果分析

plot(ynn,'r*-');hold on;
plot(line_data,'k','linewidth',2);
plot(output_test,'bo-');
plot(prediction_value_a,'g*-');

legend('horizontal prediction' , 'vertical prediction' ,'real value', 'two dimension prediction');

xlabel('time(minutes)');
ylabel('traffic value(MBits/s)');
%补绘二维预测误差分布
figure(3);
axis_step = 4;
axis_min = - ceil(max([max(abs(ynn - output_test)),max(abs(line_data' - output_test)),max(abs(prediction_value_a' - output_test))])/axis_step)*axis_step;
axis_max = - axis_min;

subplot(3,1,1);
hist(ynn - output_test,[axis_min:axis_step:axis_max]);
title('horizontal prediction','fontsize',12);

subplot(3,1,2);
hist(line_data' - output_test,[axis_min:axis_step:axis_max]);
title('vertical prediction','fontsize',12);

subplot(3,1,3);
hist(prediction_value_a' - output_test,[axis_min:axis_step:axis_max]);
title('two dimension prediction','fontsize',12);

% 平滑 a 误差分析 MSE 和 方差
figure_4 = figure(4);
MSE_VAR_array = [sum((ynn - output_test).^2)/length(ynn), sum((line_data' - output_test).^2)/length(line_data) , ...
    sum((prediction_value_a' - output_test).^2)/length(output_test); ...
    std(ynn - output_test).^2, std(line_data' - output_test).^2 ,std(prediction_value_a' - output_test).^2 ...
    ];
bar_hander = bar(MSE_VAR_array,'grouped');
legend(bar_hander,'horizontal prediction','vertical prediction','two dimension prediction');
set(gca,'xticklabel' , {'Mean Squared Error' ,'Square Deviation'},'fontsize' ,12);


% 命令窗口打印输出
fprintf('数据生成器参数: 波动率:%f 横向数据天数:%d 纵向数据天数:%d 密集度：%d \n',fluctuate ,horizontal_num_day ,vertical_num_day ,deta );
fprintf('小波神经网络参数: 输入节点数:%d 隐含层节点数:%d 输出节点数: %d\n',node_number.input , node_number.hidden , node_number.output);
fprintf('ARIMA 算法模型参数>> \n 差分次数d:%d AR 阶数 p:%d MA 阶数 q:%d\n',Arima_params.I,Arima_params.p,Arima_params.q);
fprintf('平滑 a 值使用的权值:%f\n',Single_params_a.W);
fprintf('MSE>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(1,:));
fprintf('方差>>\n 横向预测: %f 纵向预测: %f 二维预测: %f \n',MSE_VAR_array(2,:));

