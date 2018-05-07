clear;
loc='H';
%% Load data
if strcmp(loc,'H')
    dir='C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\25.ChinaHK_Connect_Quality_Factor\QFactorModel\';
else
    dir='O:\langyu\2. InvestmentProcess\SmartBetaModel\QualityFactorModel\QualityFactorModel\';
end

load(strcat(dir,'hkqfactorscreenfulltimeseries.mat')); %Daily price data
timestamp=ScreenFullTS.full.timestamp;
dat=ScreenFullTS.full.PX_LAST;
stockname=fieldnames(dat); stockname=stockname(2:end-1);
dat=table2array(dat); %price time series
retdat=tick2ret(dat);%return time series

bid_ask_spread=0.0002;

%% Tuning parameters 
% [Optimal_Parameter_name_table,Sharpe_Table]=EWMAC_Tuning_forstock(retdat,bid_ask_spread);
% 
% save Tuning_output.mat Optimal_Parameter_name_table Sharpe_Table

%% Result
% The best parameter in terms of sharpe ratios is X_16_64 after running for
% 385 Hong Kong stocks.Please see Tuning_output.xlsx for conclusion.
fast=16;
slow=64;
%% Generate EWMAC signals
bidask_spread=0.0005;
EWMACsignal=[];
Forecastscalar=[];
forecastscalar=4.715; %average forecast scalar from output
for i=2:size(stockname)+1
    price=dat(:,i);
    matt = EWMAC(price,[0;tick2ret(price)],fast,slow,bidask_spread,0.2,'',forecastscalar);
    EWMACsignal=horzcat(EWMACsignal, matt.signal);
%     Forecastscalar=horzcat(Forecastscalar,matt.forecastscalar); %for calculating forecastscalar (Not a part of main script)
end

%% Output EWMAC signal to FinancialDailyData.mat (merge it with other valuation factors)
load(strcat(dir,'FinancialDataDaily.mat')); %Daily price data
datestring=datestr(datenum(timestamp,'dd/mm/yyyy'),'yyyymmdd'); %datestring in MACD model
dailyscreenname=fieldnames(FinancialDataDaily);
for q=1:size(dailyscreenname,1)-1

    screenname=dailyscreenname{q};screennamedate=screenname(7:end); %get the date of screen
    [~,loc]=ismember(screennamedate,cellstr(datestring));
    
    stockname_check=strcmp(strcat(FinancialDataDaily.Screen20150105.stockname,'_Equity'),stockname); %check stock name matching in two places
    if sum(stockname_check)~=size(stockname,1)
        warning(strcat('In ',screenname,', stockname does not match within EWMACsignal mat'));
    end
    FinancialDataDaily.(dailyscreenname{q}).EWMACsignal=transpose(EWMACsignal(loc,:));
end   

save(strcat(dir,'FinancialDataDaily.mat'),FinancialDataDaily);

msgbox('EWMAC signals have written into FinancialDataDaily.mat');
beep
