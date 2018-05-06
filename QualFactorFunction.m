function [ScreenFullList,QFactorScreenFullTS]=QualFactorFunction(Country,ScreenName,c,runBBG,neutralscheme)
%Returns FAMA FRENCH factor returns for a given country. 
%Input argument 1 = ountry which is two letter (US,UK,EU,JP)
%Input argument 2 = name of the screen which is setup in BBG (e.g. US FAMA FRENCH)
%Input argument 4 = runBBG='Y' or 'N' rerun EQS from bloomberg o/w reload
%screen saved in database

%Determines country then assigns appriopriate tickers for Rf and Rm
RfTickerVectr = {'USGG3M Index'}'; %HK. Type "Generic" in BBG for more
RmTickerVectr = {'HSCEI Index'}'; %HK

if strcmp(Country,'HK')
    RfTicker  = RfTickerVectr(1);
    RmTicker = RmTickerVectr(1);    
else
    warndlg('Invalid Country Name')
    return %stop if haven't got valid country
end

%% Screening
DateVector={'20100131','20100430','20100731','20101031',...
    '20110131','20110430','20110731','20111031',...
    '20120131','20120430','20120731','20121031',...
    '20130131','20130430','20130731','20131031',...
    '20140131','20140430','20140731','20141031',...
    '20150131','20150430','20150731','20151031',...
    '20160131','20160430','20160731','20161031',...
    '20170131','20170430','20170731','20171031',...
    '20180131'};

%DateVector = datestr(busdate(datenum(DateVector,'yyyymmdd'),-1)); %prior business day

QualFactorFull=table;
neutralscheme='SizeNeutral';% 'SectorNeutral'
    
Tickerlist=[];    
StartDateRef = 21; %HK only available from 20150131
for i=StartDateRef:size(DateVector,2)
     if i == StartDateRef %only want to load files if we're not on first loop. 
        load(sprintf('%s','QualityFactorModel\',Country,'QFactorScreenFullList.mat'))
        load(sprintf('%s','QualityFactorModel\',Country,'QFactorScreenFullTimeseries.mat'))
     end
     
     if strcmp(runBBG,'Y')    
 %% Get the screen   
        FirstDate = {'PiTDate' ,DateVector{i}};
        ScreenList=  eqs(c,ScreenName,[],[],[],'overrideFields',FirstDate); %when running on BT's machine
        if strcmp(ScreenName,'ChinaHKSouthB Quality')
            [~,idx] = unique(ScreenList(2:end,2)); %remove duplicates
            ScreenList=ScreenList([1;idx+1],:);
        end
        Ticker=ScreenList(2:end,1); %Ticker 
        Ticker=strcat(Ticker,' Equity');
        Tickerlist=vertcat(Tickerlist,Ticker);
        
        screenname=strcat('Screen',DateVector{i});
        ScreenFullList.(screenname)=ScreenList;
        save(sprintf('%s','QualityFactorModel\',Country,'QFactorScreenFullList.mat'),'ScreenFullList');
     else
        screenname=strcat('Screen',DateVector{i});
        ScreenList=ScreenFullList.(screenname);
        Ticker=ScreenList(2:end,1); %Ticker 
        Ticker=strcat(Ticker,' Equity');
        Tickerlist=vertcat(Tickerlist,Ticker);
     end
     disp(strcat(DateVector{i}, ' is completed'));
end

 %% Grab time series
        [~,tickidx] = unique(Tickerlist); %remove duplicates in the full ticker list
        Tickerlist=Tickerlist(tickidx);
        field={'PX_LAST'};
        period='daily';
        currency=[];
        fromdate=datestr(busdate(datenum(DateVector{21},'yyyymmdd'),-1)-365,'mm/dd/yyyy');
        if i==size(DateVector,2)
            todate=datestr(today()-1,'mm/dd/yyyy');
        else
            todate=datestr(busdate(datenum(DateVector{i+1},'yyyymmdd'),-1),'mm/dd/yyyy');
        end

        Dat.Rfdat=bbggethistdata(RfTicker,field,fromdate,todate,period,currency); %rf
        Dat.Rmdat=bbggethistdata(RmTicker,field,fromdate,todate,period,currency); %rm
        fulldat=bbggethistdata(vertcat(RmTicker, Tickerlist),field,fromdate,todate,period,currency);
        fulldat.(char(field(1))).(1)=[];
        Dat.full=fulldat;
        Dat.ticker=Tickerlist;
        ScreenFullTS=Dat; %created for storing just raw data.
        %save data
        save(sprintf('%s','QualityFactorModel\',Country,'QFactorScreenFullTimeseries.mat'),'ScreenFullTS');


% %% Generate return time series
% % if strcmp(runBBG,'N')
%     Factts=table;
%     fname=fieldnames(Dat);
%     timestamp=datenum(Dat.full.timestamp,'dd/mm/yyyy'); timestamp=datestr(timestamp(2:end),'dd/mm/yyyy');
%     Factts.Date=timestamp;
% 
%     for j=1:3 
%         factor=Dat.(fname{j});
%         factts=table2array(factor.PX_LAST);
% 
%         if ~strcmp(fname{j},'Rfdat') %if not equal to Rfdat (we don't want to caculate returns for interest rates)
%             factts=tick2ret(factts);
%             factts(factts>0.5)=0;
%             factts(isnan(factts))=0;
%             
%         else
%             factts=factts(2:end,:)/100/250;
%         end
%         Factts.(fname{j})=smartmean(factts,2); %Equal weighted portfolio return     
%     end
%     
%     %% Weighting schemes
%     wgtscheme='EW';%'RW' 'EW: Equal weighting; 'RW: rank weighting
%     Weight=table;
%     Weight.(fname{3})=ones(length(Ticker),1)*(1/length(Ticker));
% 
%     rankscheme='pctile'; %'zscore' & 'pctile'
%     rankthreshold=0.3;
% 
% 
%     %% size factors------------------------------------------------
%         %Market Cap
%         MarktCap=cell2mat(ScreenList(2:end,4)); %MarketCap
%         MarktCap_wgt=SixFactor_Genwgts(MarktCap,rankscheme,0.1,wgtscheme,'');
%         MarktCap_wgt=-MarktCap_wgt; %small cap has higher weights;
%         Factts.MarktCap=factts*MarktCap_wgt';
%         Weight.MarktCap=MarktCap_wgt';
%     %% value factors
%         if strcmp(neutralscheme,'SizeNeutral')
%             neutralfactorWgt=MarktCap_wgt;
%         else
%         end
%         %PB
%         PB=cell2mat(ScreenList(2:end,3)); %PB ratio
%         PB(PB>20)=NaN; %remove extreme values
%         PB_wgt=SixFactor_Genwgts(PB,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         PB_wgt=-PB_wgt; %lower PB has higher weigths;
%         Factts.PB=factts*PB_wgt';
%         Weight.PB=PB_wgt';
%         %CFO2EV
%         CFO2EV=cell2mat(ScreenList(2:end,8)); %CFO/EV
%         CFO2EV_wgt=SixFactor_Genwgts(CFO2EV,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.CFO2EV=factts*CFO2EV_wgt';
%         Weight.CFO2EV=CFO2EV_wgt';
%         %FwdE2P
%         FwdE2P=cell2mat(ScreenList(2:end,10)); %Forward Earning yield
%         FwdE2P_wgt=SixFactor_Genwgts(FwdE2P,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.FwdE2P=factts*FwdE2P_wgt';
%         Weight.FwdE2P=FwdE2P_wgt';
%         %TrailE2P
%         TrailE2P=cell2mat(ScreenList(2:end,11)); %Trailing Earning yield
%         TrailE2P_wgt=SixFactor_Genwgts(TrailE2P,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.TrailE2P=factts*TrailE2P_wgt';
%         Weight.TrailE2P=TrailE2P_wgt';
%         %EBITDA2EV
%         Ebitda2EV=1/cell2mat(ScreenList(2:end,14));% EBIDA/EV
%         Ebitda2EV_wgt=SixFactor_Genwgts(Ebitda2EV,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.Ebitda2EV=factts*Ebitda2EV_wgt';
%         Weight.Ebitda2EV=Ebitda2EV_wgt';
%         %BB/P
%         BB2P=cell2mat(ScreenList(2:end,13));%Dividend +buyback/ price
%         BB2P_wgt=SixFactor_Genwgts(BB2P,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.BB2P=factts*BB2P_wgt';
%         Weight.BB2P=BB2P_wgt';
%     %% quality factors
%         %O/P
%         OP=cell2mat(ScreenList(2:end,15)); %Operating profitability
%         OP_wgt=SixFactor_Genwgts(OP,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.OP=factts*OP_wgt';
%         Weight.OP=OP_wgt';
%         %D/E
%         D2E=cell2mat(ScreenList(2:end,9)); %Debt/Equity ratio
%         D2E_wgt=SixFactor_Genwgts(D2E,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         D2E_wgt=-D2E_wgt;
%         Factts.D2E=factts*D2E_wgt';
%         Weight.D2E=D2E_wgt';
%     %% momentum factors
%         %Ret1
%         Ret1=cell2mat(ScreenList(2:end,5)); %past 1 month return
%         Ret1_wgt=SixFactor_Genwgts(Ret1,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Ret1_wgt=-Ret1_wgt; %lower 1month return, higher the weights
%         Factts.Ret1=factts*Ret1_wgt';
%         Weight.Ret1=Ret1_wgt';
%         %Ret9
%         Ret9=cell2mat(ScreenList(2:end,6)); %past 9 month return(skipping last 1 month)
%         Ret9_wgt=SixFactor_Genwgts(Ret9,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.Ret9=factts*Ret9_wgt';
%         Weight.Ret9=Ret9_wgt';
%         %Earnrev9
%         Earnrev9=cell2mat(ScreenList(2:end,7));%estimate earning changes over past 9 months
%         Earnrev9_wgt=SixFactor_Genwgts(Earnrev9,rankscheme,0.3,wgtscheme,neutralscheme,neutralfactorWgt);
%         Factts.Earnrev9=factts*Earnrev9_wgt';
%         Weight.Earnrev9=Earnrev9_wgt';
% 
%         Dat.Factts=Factts;
%         Dat.Weight=Weight;
%         Dat.Ticker=Ticker;
% 
%     %%save data
%     screenname=strcat('Screen',DateVector{i});%create a name of screen of each loop
%     QFactorScreenFullTS.(screenname)=Dat;
% 
%     if strcmp(neutralscheme,'SizeNeutral')
% %         SixFactorScreenFullTS.type='SizeNeutral';
%         save(sprintf('%s','Equity\SixFactorModel\',Country,'SectorNeutralScreenFullTimeseries.mat'),'SixFactorScreenFullTS');
%     elseif strcmp(neutralscheme,'SectorNeutral')
% %         SixFactorScreenFullTS.type='SectorNeutral';
%         save(sprintf('%s',Country,'6FactorScreenFullTimeseries.mat'),'SixFactorScreenFullTS');
%     end
% % end

end