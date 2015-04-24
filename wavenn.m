function wavenn(Force_train)
%% ��ջ�������
close all;
%% �����������
load traffic_flux input output input_test output_test

M=size(input,2); %����ڵ����
N=size(output,2); %����ڵ����

n=6; %���νڵ����
lr1=0.01; %ѧϰ����
lr2=0.001; %ѧϰ����
maxgen=400; %��������

%Ȩֵ��ʼ��
Wjk=randn(n,M);Wjk_1=Wjk;Wjk_2=Wjk_1;
Wij=randn(N,n);Wij_1=Wij;Wij_2=Wij_1;
a=randn(1,n);a_1=a;a_2=a_1;
b=randn(1,n);b_1=b;b_2=b_1;

%�ڵ��ʼ��
y=zeros(1,N);
net=zeros(1,n);
net_ab=zeros(1,n);

%Ȩֵѧϰ������ʼ��
d_Wjk=zeros(n,M);
d_Wij=zeros(N,n);
d_a=zeros(1,n);
d_b=zeros(1,n);

%% ����������ݹ�һ��
[inputn,inputps]=mapminmax(input');
[outputn,outputps]=mapminmax(output'); 
inputn=inputn';
outputn=outputn';

error=zeros(1,maxgen);
%% ����ѵ��
if ~Force_train

   load ('traffic_flux' , 'Wjk','a','b','Wij' ) ;
   disp(['ʹ�ñ���ģ��Ԥ��' ]);

else
    i = 1;
    while (i <= maxgen) || ((i>1) && error(i-1) < 35)
        %����ۼ�
        error(i)=0;
        % ѭ��ѵ��
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
                    y=y+Wij(k,j)*temp;   %С������
                end
            end

            %��������
            error(i)=error(i)+sum(abs(yqw-y));

            %Ȩֵ����
            for j=1:n
                %����d_Wij
                temp=mymorlet(net_ab(j));
                for k=1:N
                    d_Wij(k,j)=d_Wij(k,j)-(yqw(k)-y(k))*temp;
                end
                %����d_Wjk
                temp=d_mymorlet(net_ab(j));
                for k=1:M
                    for l=1:N
                        d_Wjk(j,k)=d_Wjk(j,k)+(yqw(l)-y(l))*Wij(l,j) ;
                    end
                    d_Wjk(j,k)=-d_Wjk(j,k)*temp*x(k)/a(j);
                end
                %����d_b
                for k=1:N
                    d_b(j)=d_b(j)+(yqw(k)-y(k))*Wij(k,j);
                end
                d_b(j)=d_b(j)*temp/a(j);
                %����d_a
                for k=1:N
                    d_a(j)=d_a(j)+(yqw(k)-y(k))*Wij(k,j);
                end
                d_a(j)=d_a(j)*temp*((net(j)-b(j))/b(j))/a(j);
            end

            %Ȩֵ��������      
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
%% ����Ԥ��
%Ԥ�������һ��
x=mapminmax('apply',input_test',inputps);
x=x';
yuce=zeros(92,1);
%����Ԥ��
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
%Ԥ���������һ��
ynn=mapminmax('reverse',yuce,outputps);

%����ģ��
save('traffic_flux.mat', 'Wjk','a','b','Wij','input', 'output', 'input_test', 'output_test');

%ȡǰ�����ֵ������ֵ��
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

% �������

figure_2 = figure(2);

plot(ynn,'r*:')
hold on
plot(line_data,'k','linewidth',2)
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
% Ԥ�������һ��
x=mapminmax('apply',input',inputps);
x=x';
yuce=zeros(length(input),1);
% ����Ԥ��
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
%Ԥ���������һ��
 pre_data =mapminmax('reverse',yuce,outputps);

 %���
 deviation_x = [(pre_data - output)' , (ynn - output_test)'];
 deviation_y = [line_data - temp_line(1,[5:96]) ,line_data - temp_line(2,[5:96]) ,line_data - temp_line(3,[5:96]) ,(line_data' - output_test)'];
 
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
 disp(['Single_params_a: ' num2str(Single_params_a.W)]);
 % �ö�άԤ�ⷽ�� Ԥ������ֵ  pre_value = a * xt + (1-a) * yt 
 % ������ ynn ��һ�죩 �� line_data ��һ�죩 �� deviation_x �����죩�� deviation_y �����죩
 % ��output_test  ��ʵֵ��

 % ����һ���� a ʹ�õ�ָ��ƽ��,����Ԥ�����
pre_a = implement_Single(Single_params_a,value_a(1,end-length(output_test)+1:end));
prediction_value_a = pre_a.*ynn' + (1-pre_a).*line_data;
prediction_value_a(1,1) = output_test(1,1);

% ����ʹ�õ� a ֵ����
figure(figure_1);
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
