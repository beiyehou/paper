function main( Force_train,Force_ARIMA_train )
% ��ջ�������
close all;
% �����������
vertical_num_day  = 33;
horizontal_num_day = 4;
fluctuate = 0.05;

[ vertical_traffic_data , horizontal_traffic_data , new_data ] = data_producer( vertical_num_day , horizontal_num_day, fluctuate );

M = 3; N = 1; n = 4; 

% ����С��������ڵ�ṹ��
node_number.input = M;
node_number.hidden = n;
node_number.output = N;

% ѵ��������

Wave_params = wave_nerve(horizontal_traffic_data ,horizontal_num_day, node_number ,Force_train);

input_out_data = data_cut(horizontal_traffic_data,horizontal_num_day,M);
output = input_out_data.output';
output_out_data = data_cut(new_data,1,M);
output_test = output_out_data.output';

% ѵ�� arima ģ��
if Force_ARIMA_train
    Arima_params = train_arima( vertical_traffic_data(:,1) );
    save('ARIMA_params.mat', 'Arima_params');
else
   load ('ARIMA_params.mat' , 'Arima_params') ;
   disp(['ARIMA ʹ�ñ���ģ��' ]);
end

disp(Arima_params);

line_data = zeros(1,length(new_data));
for i=1:1:length(new_data)
    prediction_temp_data = [vertical_traffic_data(:,i)' new_data(1,i)];
    predicton_out = implement_arima( Arima_params , prediction_temp_data);
    line_data(1,i) = predicton_out(1,end);
    disp(['arima:' num2str(i) '��'  '��' num2str(line_data(1,i) - new_data(1,i))]);
end
% line_data = sum(vertical_traffic_data)/size(vertical_traffic_data,1);
line_data = line_data(1,node_number.input+1:end);
% ʹ������·Ԥ��
ynn = implement_Wave_nerve(new_data,1,node_number,Wave_params);

% �������

figure_2 = figure(2);

plot(ynn,'r*:')
hold on
% plot(line_data,'k','linewidth',2)
plot(output_test,'bo--')


title('Ԥ�� IP ����','fontsize',12)
xlabel('ʱ���')
ylabel(' IP ����')


figure_3 = figure(3);
subplot(3,2,[1 2]);
hist(ynn - output_test,[-100:4:100]);
title('����Ԥ�����ķֲ�','fontsize',12)
subplot(3,2,[3 4]);
hist(line_data' - output_test,[-100:4:100]);
title('�������ķֲ�','fontsize',12)

% ���Ȼ��ǰ������������

 pre_data =implement_Wave_nerve(horizontal_traffic_data,horizontal_num_day,node_number,Wave_params);

 
 %���
 deviation_x = [(pre_data - output)' , (ynn - output_test)'];
 deviation_y = [line_data - temp_line(1,[M+1:96]) ,line_data - temp_line(2,[M+1:96]) ,line_data - temp_line(3,[M+1:96]) ,(line_data' - output_test)'];
 
%���Ԥ����㵥ָ��ƽ���㷨����
Single_params_x = training_single_smoothing( deviation_x , 0.01 );
Single_params_y = training_single_smoothing( deviation_y , 0.01 );

% ������ ynn ��һ�죩 �� line_data ��һ�죩 �� deviation_x �����죩�� deviation_y �����죩 

%��ǰ������� a ֵ �� ect = a * ex + (1-a) * ey ;
deviation_x = dimension_change(deviation_x,'row');
deviation_y = dimension_change(deviation_y,'row');
value_a = [];
value_a = calculate_a(deviation_x , deviation_y);


% ���� a ֵ�ĵ�ָ��ƽ���㷨����
 Single_params_a = training_single_smoothing( value_a(1,1:(end-length(output_test))) , 0.01 );   
%  Single_params_a.W = 0.4 ;
 disp(node_number);
 disp(['Single_params_a: ' num2str(Single_params_a.W)]);
 % �ö�άԤ�ⷽ�� Ԥ������ֵ  pre_value = a * xt + (1-a) * yt 
 % ������ ynn ��һ�죩 �� line_data ��һ�죩 �� deviation_x �����죩�� deviation_y �����죩
 % ��output_test  ��ʵֵ��

 % ����һ���� a ʹ�õ�ָ��ƽ��,����Ԥ�����
pre_a = implement_Single(Single_params_a,value_a(1,end-length(output_test)+1:end));
prediction_value_a = pre_a.*ynn' + (1-pre_a).*line_data;
prediction_value_a(1,1) = output_test(1,1);

% ����ʹ�õ� a ֵ����
figure_1 = figure(1);
plot(value_a(1,end-length(output_test)+1:end),'ko-','linewidth',1.5);
hold on;
plot(pre_a,'ro-','linewidth',1.5);


%�����άԤ����
figure(figure_2);
plot(prediction_value_a,'g*:');

%�����άԤ�����ֲ�
figure(figure_3);
subplot(3,2,5);
hist(prediction_value_a' - output_test,[-100:4:100]);
title('ƽ�� a ��άԤ�����ķֲ�','fontsize',12);
% ƽ�� a ������ MSE �� ����
figure_4 = figure(4);
subplot(1,2,1);
MSE_VAR_array = [sum((ynn - output_test).^2)/length(ynn), sum((line_data' - output_test).^2)/length(line_data) , ...
    sum((prediction_value_a' - output_test).^2)/length(output_test); ...
    std(ynn - output_test).^2, std(line_data' - output_test).^2 ,std(prediction_value_a' - output_test).^2 ...
    ];
bar_hander = bar(MSE_VAR_array,'grouped');
legend(bar_hander,'����Ԥ��','����Ԥ��','��άԤ��');
set(gca,'xticklabel' , {'MSE' ,'����'},'fontsize' ,12);
title('ƽ�� a Ԥ�����Ľ���Ƚ�ͼ �����һ��Ϊ MSE ---- �Ҳ�һ��Ϊ���');
fprintf('MSE>>\n ����Ԥ��: %f ����Ԥ��: %f ��άԤ��: %f \n',MSE_VAR_array(1,:));
fprintf('����>>\n ����Ԥ��: %f ����Ԥ��: %f ��άԤ��: %f \n',MSE_VAR_array(2,:));
%���������������һʱ�� ex �� ey �ĵ�ָ��ƽ��ֵ���ú���Ԥ���� ex �� ey ���� a ֵ
pre_ex = implement_Single(Single_params_x,deviation_x(1,end-length(output_test)+1:end));
pre_ey = implement_Single(Single_params_y,deviation_y(1,end-length(output_test)+1:end));
value_a = calculate_a(pre_ex,pre_ey);
prediction_ex_ey = value_a.*ynn' + (1-value_a).*line_data;
prediction_ex_ey(1,1) = output_test(1,1);
figure(figure_2);
plot(prediction_ex_ey,'m*:');
legend('����Ԥ��' , '����Ԥ��' ,'��ʵֵ', 'ƽ�� a ��άԤ��', 'ƽ�� ex ey ��άԤ��');

figure(figure_1);
plot(value_a,'go-','linewidth',1.5);
legend('a ����ʵֵ','ƽ�� a ʹ�õ� a ֵ����' ,'ƽ�� ex ey ʹ�õ� a ֵ����');
% ƽ�� ex ey ������ MSE �� ����
figure(figure_4);
subplot(1,2,2);
bar_hander = bar([sum((ynn - output_test).^2)/length(ynn), sum((line_data' - output_test).^2)/length(line_data) , ...
    sum((prediction_ex_ey' - output_test).^2)/length(output_test); ...
    std(ynn - output_test).^2, std(line_data' - output_test).^2 ,std(prediction_ex_ey' - output_test).^2 ...
    ],'grouped');
legend(bar_hander,'����Ԥ��','����Ԥ��','��άԤ��');
set(gca,'xticklabel' , {'MSE' ,'����'},'fontsize' ,12);
title('ƽ�� ex ey Ԥ�����Ľ���Ƚ�ͼ �����һ��Ϊ MSE ---- �Ҳ�һ��Ϊ���');
%�����άԤ�����ֲ�
figure(figure_3);
subplot(3,2,6);
hist(prediction_ex_ey' - output_test,[-100:4:100]);
title('ƽ�� ex ey ��άԤ�����ķֲ�','fontsize',12);