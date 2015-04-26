function prediction_result = implement_arima( Arima_params , data)
% 本函数用于实施 arima 算法

% Arima_params 输入模型结构体
% data 输入带预测数据
% prediction_result 输出预测结果

data = dimension_change(data,'row');
% data = data(1,end-(Arima_params.p+Arima_params.I+10):end);
% 检查是否需要差分
temp_diff = Arima_params.I;
savediffdata = [];
predict_data = data;
while temp_diff
    savediffdata = [ savediffdata predict_data(1,1) ];
    temp_diff = temp_diff - 1;
    predict_data = diff( predict_data );
end

% 实施 arima 预测
 predict_data = dimension_change(predict_data,'col');
 predict_iddata = iddata( predict_data );

 histroy_iddata =iddata( predict_iddata );

 model = armax( histroy_iddata , [Arima_params.p  Arima_params.q] );

 predict_object =  predict(model , predict_iddata , 1 );
 
 model_predict_data = predict_object.OutputData'; % 加转置转为行向量

 if size(savediffdata,2) ~= 0
      for index=size(savediffdata,2):-1:1
            model_predict_data=cumsum([savediffdata(index),model_predict_data]);   
      end
end 

 
 % 最终预测结果
 prediction_result = model_predict_data;
 
 

