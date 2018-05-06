%% Quality model construction


loc='H';
%% Load data
if strcmp(loc,'H')
    dir='C:\Users\GU\Dropbox\GU\1.Investment\4. Alphas (new)\25.ChinaHK_Connect_Quality_Factor\QFactorModel\';
else
    dir='O:\langyu\2. InvestmentProcess\SmartBetaModel\QualityFactorModel\QualityFactorModel\';
end
load(strcat(dir,'HKQFactorScreenFullList.mat')); %Quarterly Financial data
load(strcat(dir,'HKQFactorScreenFullTimeseries.mat')); %Daily price data
load(strcat(dir,'FinancialDataDaily.mat')); %Daily Financial data mat
Sector_Info=readtable(strcat(dir,'Other_Data.xlsx'),'Sheet','Sector Info','Range','A:D'); %Sector code

load QualFactorModelHK.mat
%% Prep data

stknm=cellfun(@(x) x(1:end-7),Sector_Info.Name,'UniformOutput',false);%reformat stock name
stknm=strcat('BBG', stknm);
stknm=strrep(stknm,' ','_');

stknm_px=cellfun(@(x) x(1:end-7),fieldnames(ScreenFullTS.full.PX_LAST),'UniformOutput',false);%reformat stock name in PX_LAST
stknm_px=stknm_px(2:end-1);

PX_Last=ScreenFullTS.full.PX_LAST(243:end,2:end);%adjust the price mat

screenname=strcat('Screen',FinancialDataDaily.timestamp);

positionTable=zeros(size(PX_Last)); %set up trading position mat
LongonlyposTable=zeros(size(PX_Last)); %set up trading position mat
TopInx=NaN(size(size(PX_Last,1),35)); BottomInx=NaN(size(size(PX_Last,1),35));

for i=1:size(fieldnames(FinancialDataDaily),1)-1
    screen=FinancialDataDaily.(screenname(i,:));
    [~,ix]=ismember(screen.stockname,stknm);
    sectorcode=Sector_Info.GICS_SECTOR_CODE(ix);
    
    zscore_board=table;
    
    zscore_board.stockname=screen.stockname; %stockname
    
    %Adjustment for NetDebt2EBITDA (given some stocks have negative EBITDA,
    %set them to NaN
    screen.NetDebt2EBITDA(screen.EBITDA_T12M<0)=NaN;
    
    ratio_name={'ROE','EBITDA2EV','NetDebt2EBITDA','Debt2Eq','Beta','Vol','E2P','B2P'};

    zscore_mat=NaN(size(screen,1),8);
    for k=1:8
        %% step 1: restrict outliers
        ratio=screen.(ratio_name{k});
        ratio_mid=median(ratio,'omitnan');
        ratio_upperband=ratio_mid+2*std(ratio,'omitnan');
        ratio_lowerband=ratio_mid-2*std(ratio,'omitnan');
        ratio(ratio<ratio_lowerband)=ratio_lowerband;
        ratio(ratio>ratio_upperband)=ratio_upperband;
        ratio_std=std(ratio,'omitnan');

        %% step 2: sector neutral
        sector_GICS={'Consumer_Discretionary','Consumer_Staples','Energy',...
            'Financials','Health_Care','Industrials','Information_Technology',...
            'Materials','Real_Estate','Telecomm','Utilities'};
        for j=1:11 %11 sectors
            [id,ix]=ismember(sectorcode,j); %locate sector code in the screen
            zs=ratio(sectorcode==j); %strip out stocks in the sector
            zs_mid=median(zs,'omitnan');
            zs_std=std(zs,'omitnan');
            zs_min=min(zs);
            zs_max=max(zs);
            
            if k==5|| k==6 %Beta & Vol prefer lower ratio
                zscore_mat(sectorcode==j,k)=-(zs-zs_mid)./zs_std;
            else
                zscore_mat(sectorcode==j,k)=(zs-zs_mid)/zs_std;
            end
            
            %step 3: collect sector statsitics
            sectorstats.(sector_GICS{j})(i,(k-1)*5+1:(k-1)*5+5)=[sum(id) zs_mid zs_std zs_min zs_max];%sector stats collects:# of stocks, median, std, min and max of ratios
        end
    end
    
    %% step 4: combine zscore
    zscore_mat(zscore_mat<-3)=-3; %cap and bottom extreme zscore values
    zscore_mat(zscore_mat>3)=3;
    
    for p=1:size(zscore_mat,1)
        if sum(isnan(zscore_mat(p,:)))>=4 
            ipx(p)=NaN;
        else
            ipx(p)=0;
        end
    end
    combined_zscore=smartmean(zscore_mat,2);
    combined_zscore=combined_zscore+ipx';%if more than 4 fundamental zscores are NaN, then treat combined_zscore=NaN
    
    %% ****[Tempoary part] for single ratio only****
    combined_zscore=zscore_mat(:,8);
    
    %%
    
    [nm,inx]=sort(combined_zscore);
    inx=inx(~isnan(nm)); %remove NaN
    topinx=flipud(inx(round(size(inx,1)*0.9):end)); %top 10% ranked by zscore
    bottominx=inx(1:round(size(inx,1)*0.1));%bottom 10% ranked by zscore
    TopName=screen.stockname(topinx); %Top name
    BottomName=screen.stockname(bottominx);%Bottom name
    
%%  step 5: contruct Equal weighted portfolio position (long-short & long-only)

    [~,toppos]=ismember(TopName,stknm_px);
    [~,bottompos]=ismember(BottomName,stknm_px);
    
    positionTable(i,toppos)=1/size(toppos,1); %Equal weighted long position
    positionTable(i,bottompos)=-1/size(bottompos,1); %Equal weighted short position
    
    LongonlyposTable(i,toppos)=1/size(toppos,1); % Long only
%% step 6: collect data    
    zscore_board=horzcat(zscore_board,array2table(zscore_mat,'VariableNames',ratio_name)); %combine to form zscoreboard table
    ZScore_board.(screenname(i,:))=zscore_board;
    TopInx(i,1:length(topinx))=topinx';
    BottomInx(i,1:length(bottominx))=bottominx';
    
%     QualFactorModelHK.SectorStats=sectorstats;  %temp
%     QualFactorModelHK.ZScoreBoard=ZScore_board;  %temp
    QualFactorModelHK.PickedStocks.TopName=TopInx;
    QualFactorModelHK.PickedStocks.BottomName=BottomInx;
    
    if ismember(i,[100 200 300 400 500 600 700 800])
    save QualFactorModelHK.mat QualFactorModelHK;
    end

    i
end

%% step 7: simulate strategy pnl (quicky)
ret=[NaN(1,size(PX_Last,2)); tick2ret(table2array(PX_Last))];
%Long-short version
positionTable=backshift(1,positionTable);
TC_roundtrip=0.00013*2; %tradingcost
tc=TC_roundtrip*ones(size(positionTable));%trading cost estimate percentage
pnl=smartsum(positionTable.*(ret-tc), 2); %daily return time series
pnl(isnan(pnl))=0;
apr_si=prod(1+pnl).^(252/length(pnl))-1; %annualised returns since inception
sharpe_si=mean(pnl)*sqrt(252)/std(pnl); %sharpe ratio since inception
maxdd_si=maxdrawdown(100*cumprod(1+pnl)); %maxdrawdown since inception
LongShortStrat.ts=pnl;
LongShortStrat.stats=array2table([apr_si sharpe_si maxdd_si],'VariableNames',{'APR','SharpeRatio','MaxDD'});

%Long-only version
LongonlyposTable=backshift(1,LongonlyposTable);
TC_roundtrip=0.00013*2; %tradingcost
tc=TC_roundtrip*ones(size(LongonlyposTable));%trading cost estimate percentage
pnl=smartsum(LongonlyposTable.*(ret-tc), 2); %daily return time series
pnl(isnan(pnl))=0;
apr_si=prod(1+pnl).^(252/length(pnl))-1; %annualised returns since inception
sharpe_si=mean(pnl)*sqrt(252)/std(pnl); %sharpe ratio since inception
maxdd_si=maxdrawdown(100*cumprod(1+pnl)); %maxdrawdown since inception
LongOnlyStrat.ts=pnl;
LongOnlyStrat.stats=array2table([apr_si sharpe_si maxdd_si],'VariableNames',{'APR','SharpeRatio','MaxDD'});

QualFactorModelHK.LongShortStrategy=LongShortStrat;
QualFactorModelHK.LongOnlyStrategy=LongOnlyStrat;

%%

QualFactorModelHK.version='v1.01';
QualFactorModelHK.SectorStats.timestamp=FinancialDataDaily.timestamp;
QualFactorModelHK.Comment='Set Beta and Volatility as lower the better';
save QualFactorModelHK.mat QualFactorModelHK;
