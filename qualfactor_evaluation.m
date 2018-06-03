%% Load model and data
load QualFactorModelHKV1.5.mat
load QFactorModel/hkqfactorscreenfulltimeseries.mat

Topinx=QualFactorModelHK.PickedStocks.TopName; %Top pick stock index
ticker=ScreenFullTS.ticker;
ticker=strcat('BBG',ticker);ticker=strrep(ticker,' ','_');

for j=1:size(Topinx,1)
    
    if strcmp(rebalanced,'Y')
        inx=Topinx(j,:);inx=inx(inx~=0);
        TopName=ticker(inx,:);
    end
    
end
%% Changes in TopPick Names

new_names=NaN(size(Topinx,1),1);
gap=60;
for i=61:gap:size(Topinx,1)
    pick_t1=Topinx(i,:); pick_t1=pick_t1(pick_t1~=0);
    pick_t0=Topinx(i-gap,:); pick_t0=pick_t0(pick_t0~=0);
    ix=ismember(pick_t1,pick_t0);
    new_names(i)=sum(ix==0);
end