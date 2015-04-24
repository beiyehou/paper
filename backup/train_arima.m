function Arima_params = train_arima( data )
% ����������ѵ���ó� arima ģ�͵ĸ�������

% data ��������
% Arima_params ������� (�ṹ��)

source_data = dimension_change(data,'row');

% ����һ��������
% source_data = detrend( source_data );
% trend_data = source_data - data;
% fit_p = polyfit( [1:length(trend_data)] , trend_data , 1 );

% �����ִ���
H = adftest( source_data );
difftime = 0;
temp_data = source_data;
while ~H
    temp_data = diff( temp_data );
    difftime = difftime + 1;
    H = adftest( temp_data );
end

% ���� p q ֵ
temp_data = dimension_change(temp_data , 'col');
u = iddata(temp_data);
check = [];

for p = 1:5          
    for q = 1:5                  
        m = armax(u,[p q]);        
        AIC = aic(m);              
        check = [check;p q AIC];
    end
end
[best_value , best_index]= min(check(:,3));
p_best = check( best_index , 1 );
q_best = check( best_index , 2 );

% ��������
Arima_params.I = difftime;
Arima_params.p = p_best;
Arima_params.q = q_best;
Arima_params.aic = best_value;
% Arima_params.fit_p = fit_p;
Arima_params.fit_index = length( data );
Arima_params.histroy_iddata = iddata( temp_data );
