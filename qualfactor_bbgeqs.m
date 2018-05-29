%addmypath %run once

clc;clear;

genFact='Y';
runBBG='Y';

javaaddpath('F:\MATLAB\blpapi3.jar'); %when running on Langyu's PC
ScreenNames = {'US 6FACTORS','EU 6FACTORS','UK 6FACTORS','JP 6FACTORS','EM 6FACTORS','ChinaHKSouthB Quality'};

if strcmp(runBBG,'Y')
    c = blp;
else
    c=[];
end

load('QFactorModel\AllCountryQfactorDB.mat');

CountryNames = {'EU','US','UK','JP','EM','hk'};

%loops through each country
for i = 6:size(CountryNames,2)

    if strcmp(genFact,'Y')
        [ScreenFullList,ScreenFullTS]=QualFactorFunction(CountryNames{i},ScreenNames{i},c,runBBG); %gets factor full for each series
    elseif strcmp(genFact,'N')
        load( sprintf('%s','QFactorModel\',CountryNames{i},'qfactorscreenfulllist.mat'))
        load( sprintf('%s','QFactorModel\',CountryNames{i},'qfactorsScreenfulltimeseries.mat'))
    end

%     noscreens=fieldnames(ScreenFullList);
%     FactorFull=table;
%     for j=1:size(noscreens,1)
%         screen=ScreenFullTS.(noscreens{j});
%         FactorFull=vertcat(FactorFull,screen.Factts);
%     end
% %% Removes outliers (returns with absolute value greater than 20%)
% FactorFullTableArray = table2array(FactorFull(:,2:end));
% b  = abs(FactorFullTableArray)>0.20;
% FactorFullTableArray(b) = 0; %remove all with abs >20%
% c  = FactorFullTableArray(:,2:end) == 0;
% FactorFullTableArray = FactorFullTableArray(~c(:,1),:); %removes rows where all factors except the risk free rate are zero
% FactorFullNames = fieldnames(FactorFull);
% 
% DateUncleaned = datenum(FactorFull.Date,'dd/mm/yyyy');
% FactorFull2=table;
% FactorFull2.Date=datestr(DateUncleaned(~c(:,1),1),'dd/mm/yyyy');
% FactorFull3=array2table(FactorFullTableArray,'VariableNames',FactorFullNames(2:end-1));
% 
% FactorFull =horzcat(FactorFull2,FactorFull3); %overwrites existing factor full
% %% calculates factors
% FactorDB.(CountryNames{i})=FactorFull;
% writetable(FactorFull,'Equity\SixFactorModel\AllCountryFamaFactor.xlsx','Sheet',CountryNames{i});
% save('Equity\SixFactorModel\AllCountry6FactorDB.mat','FactorDB');

end

% %close(c)
% 
% %plot results EU 
% figure('name','EU')
% xaxis = datenum(FactorDB.EU.Date,'dd/mm/yyyy');
% 
% subplot(2,2,1) 
% plot(xaxis,FactorDB.EU.MKT)
% title('mkt')
% datetick('x','yyyy')
% 
