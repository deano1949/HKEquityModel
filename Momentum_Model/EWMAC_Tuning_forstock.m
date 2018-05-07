%% This script is to select best EWMAC model fast and slow parameters.

function [Optimal_Parameter_name_table,Sharpe_Table]=EWMAC_Tuning_forstock(datamtx,bid_ask_spread)
%Input: ts: return time series
%       bid_ask_spread: of instrument
%Output: Optimal_Parameter: suggested optimal parameter
%        AvgCorrel: average correlation between parameter sets
%        AvgSharpe: sharpe of parameter sets
%% Load data
load Tuning_output.mat
% Sharpe_Table=table;
% Optimal_Parameter_name_table={};
for p=22:size(datamtx,2)
    stck=datamtx(~isnan(datamtx(:,p))); %run through each stock

    if size(stck,1)<1000
        midsharpe=table;
        Optimal_Parameter_name={};
    else
    %% Boostrap
    blocks=CV_block_MC(stck,50,750);
    listname=fieldnames(blocks);
    sharpemtx=[];
    slowlist=[];
    fastlist=[];
    para_name={};


        for i=1:size(listname,1)
        name=listname{i};
        retts=blocks.(name);
        ts=ret2tick(retts,100);
        tsmtx=[];
        j=1;
        for fast=[2 4:4:64]
            for multiple=[4]
                slow=fast*multiple;
                mat=EWMAC(ts,[0;retts],fast,slow,bid_ask_spread,0.2,'','');
                tsmtx=horzcat(tsmtx,mat.performance.dailyreturn);
                sharpemtx(i,j)=mat.performance.sharpe_aftercost;
                j=j+1;       
                %Get parameter names
                if i==1
                   para_name=[para_name,strcat('X_',num2str(fast),'_',num2str(slow))];
                   slowlist=horzcat(slowlist,slow);
                   fastlist=horzcat(fastlist,fast);
                end
            end
        end
        avgcorr(:,:,i)=corr(tsmtx);
        end

        %% Parameter selection
        correllimit=0.8;

        %1st pair
        AvgCorrel=smartmean(avgcorr,3);
        midsharpe=nanmedian(sharpemtx);
        [ix,id]=sort(midsharpe(~isnan(midsharpe)),'descend');

        if ~isempty(id)
        %1st pair
        pair1=id(1);

        %2nd pair
        if length(id)==1
            pair2=pair1;
            pair3=pair1;
        else
            l=2;
            while l<=length(id)
                crosscorrel=AvgCorrel(pair1,id(l));
                if crosscorrel<correllimit
                    pair2=id(l);
                    l=l+1;
                    break
                end

                if l== length(id)
                pair2=pair1;
                end
                l=l+1;
            end

            %3rd pair
            if length(id)==3
                pair3=pair2;
            else
                if pair2==pair1
                    pair3=pair2;
                else
                    while l<=length(id)
                        crosscorrel=AvgCorrel(pair2,id(l));
                        if crosscorrel<correllimit
                            pair3=id(l);
                            break
                        end
                        if l== length(id)
                            pair3=pair1;
                        end
                        l=l+1;
                    end
                end
            end
        end
        %Optimal
        Optimal_Parameter=[fastlist(pair1) fastlist(pair2) fastlist(pair3);...
            slowlist(pair1) slowlist(pair2) slowlist(pair3)];

        AvgCorrel=array2table(AvgCorrel,'VariableNames',para_name);
        midsharpe=array2table(midsharpe,'VariableNames',para_name);
        if pair1==pair2 || pair2==pair3 || pair1==pair3
            Optimal_Parameter_name=[para_name(pair1) strcat(para_name(pair2),'_') strcat(para_name(pair3),'__')];
        else
            Optimal_Parameter_name=[para_name(pair1) para_name(pair2) para_name(pair3)];
        end
            Optimal_Parameter=array2table(Optimal_Parameter,'VariableNames',Optimal_Parameter_name,'RowNames',{'fast' 'slow'});
        else
            Optimal_Parameter={};
            AvgCorrel={};
            midsharpe={};
        end
   end
Sharpe_Table=vertcat(Sharpe_Table,midsharpe);
Optimal_Parameter_name_table=vertcat(Optimal_Parameter_name_table,Optimal_Parameter_name);

if p==[20 40 60 80 100 150 200 250 300 350] 
    save Tuning_output.mat Optimal_Parameter_name_table Sharpe_Table
end
p
end