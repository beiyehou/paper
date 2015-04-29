function   Wave_params = wave_nerve(input_sequence ,day_number, node_number ,Force_train)
% input_sequence    ������������
% node_number       ���������������ڵ�����(�ṹ��)
% day_number          �����������пɷ�Ϊ����
% Force_train           ������ʾ�Ƿ�ǿ��ѵ����· Ϊ 1 ѵ�� Ϊ 0 ʹ�ñ���ģ��
% Wave_params      ������������(�ṹ��)

% ��ʼ������
M = node_number.input;             %����ڵ����
N = node_number.output;           %����ڵ����
n = node_number.hidden;           %���νڵ����

lr1=0.01;                   %ѧϰ����
lr2=0.001;                 %ѧϰ����
maxgen=500;           %��������

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

% ������������
input = [];
output = [];
input_sequence = dimension_change(input_sequence,'row');
cut_result = data_cut(input_sequence,day_number,M);


input = cut_result.input';
output = cut_result.output';

% ����������ݹ�һ��
[inputn,inputps]=mapminmax(input');
[outputn,outputps]=mapminmax(output'); 
inputn=inputn';
outputn=outputn';

% ����ѵ��
error=zeros(1,maxgen);

if ~Force_train
   load ('saved/Wave_params.mat' , 'Wjk','a','b','Wij' ,'inputps','outputps') ;
   disp(['С��ʹ�ñ���ģ��' ]);
else
    disp(['С��ʹ���µ�ģ��']);
    i = 1;
    while (i <= maxgen) 
%         if ((i>1) && error(i-1) < 39)
%             break;
%         end
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
            error(i)=error(i)+sum((yqw-y).^2)/length(yqw);
%             error(i) = error(i) + std(yqw-y).^2;

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
        disp(['ѵ����ɣ�' num2str(i) '��']);
    end
    %����ģ��
    figure(6);plot(error);
    save('saved/Wave_params.mat', 'Wjk','a','b','Wij','inputps','outputps');
end

Wave_params.Wjk = Wjk;
Wave_params.a = a;
Wave_params.b = b;
Wave_params.Wij = Wij;
Wave_params.inputps = inputps;
Wave_params.outputps = outputps;



