%%½øĞĞ×İÏòÔ¤²â
function out =  avarege_predict(input_data , step)
out(1:step) = input_data(1:step);
for i = step + 1 : length(input_data)
    out(i) = sum(abs(input_data( i - step : i - 1)))/step;
end
% figure
% subplot(2,1,1)
% plot(input_data,'r-o','linewidth',2);hold on;
% plot(out,'k-o','linewidth',2);
% subplot(2,1,2)
% hist(input_data - out);