%% This Script is to convert Quarterly Financial data into Daily data
% Script flow diagram
% ----
% ----
% ----
loc='H';
%% Load data
if strcmp(loc,'H')
    dir='C:\Spectrion\Data\PriceData\QFactorModel\';
else
    dir='O:\langyu\2. InvestmentProcess\SmartBetaModel\QualityFactorModel\QualityFactorModel\';
end
load(strcat(dir,'HKQFactorScreenFullList.mat')); %Quarterly Financial data
load(strcat(dir,'HKQFactorScreenFullTimeseries.mat')); %Daily price data
load(strcat(dir,'FinancialDataDaily.mat')); %Daily Financial data mat
Announcement_DT=readtable(strcat(dir,'Other_Data.xlsx'),'Sheet','NL','Range','A4:NV30'); %Earning Announcment date

QuarterlyDate={'20150131','20150430','20150731','20151031',...
    '20160131','20160430','20160731','20161031',...
    '20170131','20170430','20170731','20171031',...
    '20180131'};

%Quarterly Financial Data

%% Prep data
timestamp=ScreenFullTS.full.timestamp;
timestamp=timestamp(243:end,:); %Time stamp for final list
Mkt_inx=ScreenFullTS.full.PX_LAST(243:end,1);
PX_last=ScreenFullTS.full.PX_LAST(243:end,2:end); %Daily price

timename=datestr(datenum(timestamp,'dd/mm/yyyy'),'yyyymmdd');
screenname=strcat('Screen',timename);%prep daily screen name

stockname=fieldnames(ScreenFullTS.full.PX_LAST); 
stockname=stockname(2:end-1); %stock names in daily screen
stockname=cellfun(@(x) x(1:end-7),stockname,'UniformOutput',false);%reformat stock name


QuarterlyDate=datenum(QuarterlyDate,'yyyymmdd'); %convert datestring to datenum for quarterly date
dailytimenum=datenum(timestamp,'dd/mm/yyyy');

QuarterlyScreenName=fieldnames(ScreenFullList);

Announcement_DT_nm=fieldnames(Announcement_DT);%Announcement date table name
[~,Acmt_DT_nm_inx]=ismember(stockname,Announcement_DT_nm);%locate position of stockname in Announcment date table name

finalmat=NaN(size(stockname,1),17); %final output financial data table
finalmatname={'ROE','Tot_Liab','Tot_Equity','Book_Val_PS','Basic_EPS_T12M','EV_Components',...
    'No_Shares','EBITDA_T12M','Net_Debt','P','Beta','Vol',...
    'E2P','B2P','EBITDA2EV','NetDebt2EBITDA','Debt2Eq'};

%% Calculate 1Y Beta & Volatility

ret_mat=tick2ret(table2array(ScreenFullTS.full.PX_LAST(:,2:end)));
mkt_ret=tick2ret(table2array(ScreenFullTS.full.PX_LAST(:,1)));

for k=1:size(ret_mat,2)
    beta_mat(:,k)=movingBeta(ret_mat(:,k),mkt_ret,250);
end
beta_mat=beta_mat(242:end,:); %1Y beta

vol_mat=movingStd(ret_mat,250);
vol_mat=vol_mat(242:end,:);

%% Conversion begins
for i=1:size(timename,1)
    dateInx_table=table;
    dateInx=dailytimenum(i);
    dateInx_mat=finalmat;
    qpt=dateInx<QuarterlyDate;
    [~,inx]=ismember(1,qpt);
    
    if inx~=0
        if inx==1
            prevscreen=ScreenFullList.(QuarterlyScreenName{inx});
        else
            prevscreen=ScreenFullList.(QuarterlyScreenName{inx-1}); %previous screen
        end
        currentscreen=ScreenFullList.(QuarterlyScreenName{inx});  %next screen
    else
        prevscreen=ScreenFullList.(QuarterlyScreenName{end});
        currentscreen=ScreenFullList.(QuarterlyScreenName{end});
    end
        
    prevscr_stock_nm=strrep(prevscreen(:,1),' ','_'); %convert quarterly data stock name to uniform one
    prevscr_stock_nm=strcat('BBG',prevscr_stock_nm);
    crntscr_stock_nm=strrep(currentscreen(:,1),' ','_');
    crntscr_stock_nm=strcat('BBG',crntscr_stock_nm);

    [previd,prevQFinDat_nm_inx]=ismember(stockname,prevscr_stock_nm);%locate position of stockname in Announcment date table name
    [crnvid,crntQFinDat_nm_inx]=ismember(stockname,crntscr_stock_nm);%locate position of stockname in Announcment date table name

    for j=1: size(stockname,1) %loop through each stock name
        nm=stockname{j};
        if previd(j)+crnvid(j)~=0
            nm=Announcement_DT_nm(Acmt_DT_nm_inx(j));
            try
                Ann_DT_single=Announcement_DT.(nm{1});Ann_DT_single=Ann_DT_single(~isnan(Ann_DT_single));
                Ann_DT_single=num2str(Ann_DT_single);
                Ann_DT_single=datenum(Ann_DT_single,'yyyymmdd');
                ix=Ann_DT_single<QuarterlyDate(inx);%find the right announcement date
                ix=sum(ix);
            catch
                ix=0;
            end

            if ix==0 %first available announcement date is outside the current screen
                pickscreen=currentscreen;
                pick_inx=crntQFinDat_nm_inx;
            else
                pick_Ann_DT=Ann_DT_single(ix);%announcement date falls in between previous and current screen
                if dateInx<pick_Ann_DT %today is earlier than announcement date
                    pickscreen=prevscreen;
                    pick_inx=prevQFinDat_nm_inx;
                elseif dateInx>=pick_Ann_DT %today is later than announcement date
                    pickscreen=currentscreen;
                    pick_inx=crntQFinDat_nm_inx;
                end
            end
               row_pointer=pick_inx(j);
               
               if row_pointer>0
                dateInx_mat(j,1:9)=cell2mat(pickscreen(row_pointer,5:13)); %copy financial data to final mat
                dateInx_mat(j,10)=table2array(PX_last(i,j)); %Price
                dateInx_mat(j,11)=beta_mat(i,j); % Beta
                dateInx_mat(j,12)=vol_mat(i,j); % Volatility
                dateInx_mat(j,13)=dateInx_mat(j,5)/dateInx_mat(j,10); % E/P
                dateInx_mat(j,14)=dateInx_mat(j,4)/dateInx_mat(j,10); % B/P
                
                if isnan(dateInx_mat(j,6)) %If EV_Components is NAN then treat it as zero
                    EV=dateInx_mat(j,7)*dateInx_mat(j,10);
                else
                    EV=dateInx_mat(j,7)*dateInx_mat(j,10)+dateInx_mat(j,6);
                end
                dateInx_mat(j,15)=dateInx_mat(j,8)/EV; %EBITDA/EV
                
                dateInx_mat(j,16)=dateInx_mat(j,9)/dateInx_mat(j,8); %Net Debt/EBITDA
                dateInx_mat(j,17)=dateInx_mat(j,2)/dateInx_mat(j,3); %Total Debt/Total Equity

               end               
               
        end
    end
    stockname_table=table(stockname);
    dateInx_table=array2table(dateInx_mat,'VariableNames',finalmatname);
    dateInx_table=horzcat(stockname_table,dateInx_table);
    dailymatname=strcat('Screen',timename(i,:));
    FinancialDataDaily.(dailymatname)=dateInx_table; %Get DailyData Mat constructed
    i
    if ismember(i,[100 200 300 400 500 600 700 800])
    save(strcat(dir,'FinancialDataDaily.mat'),'FinancialDataDaily');
    end
end
    
    save(strcat(dir,'FinancialDataDaily.mat'),'FinancialDataDaily');
