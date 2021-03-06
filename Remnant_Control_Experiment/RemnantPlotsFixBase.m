close all
clc

lineWidth = 1.2;
markerSize = 8;
iter = length(remnants);
% iter = 70;

% figure
% plotHandler = plot(dataHandler.inputSeq/inputInvScale, dataHandler.outputSeq/outputInvScale,...
%     '-b','linewidth',lineWidth); hold on;
% xlim([-1600 1600])
% ylim([-5 25])
% xticks([-1400 -700 0 700 1400])
% % yticks([-600 -300 0 300 600 900 1200])
% xlabel('$V$','Interpreter','latex')
% ylabel('$nm$','Interpreter','latex')
% 
% % Plot initial and final points in phase plot
% plot(0,x0,'or',...
%     'LineWidth',lineWidth,...
%     'markerSize',markerSize-2)
% plot(0,ref,'xr',...
%     'LineWidth',lineWidth,...
%     'markerSize',markerSize)
% 
% for i=1:iter
%     plot(inputs(:,i),outputs(:,i),'--b',...
%         'LineWidth',lineWidth*0.85);
% end

% DataPlotter.plotWeightFunc(baseModel.weightFunc, baseModel.inputGrid);
% xlabel('$\beta$','Interpreter','latex')
% ylabel('$\alpha$','Interpreter','latex')
% maxZ = max(max(baseModel.weightFunc));
% plotRectangle([0,0;
%     -850,0;
%     -850,1350;
%     0,1350;
%     0,0], maxZ, QLinePoints, QLineWidth);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure();
plotHandler = plot(dataHandlerSim.inputSeq, dataHandlerSim.outputSeq,...
    '-b','linewidth',lineWidth,...
    'DisplayName','Miller model loop $(u_{p+},\mathcal{Y}_{u_{p+}})$, $(u_{p-},\mathcal{Y}_{u_{p-}})$'); hold on;
xlim([-2200 2200])
ylim([-40 90])
xticks([-2100 -1400 -700 0 700 1400 2100])
% yticks([-600 -300 0 300 600 900 1200])
xlabel('$V$','Interpreter','latex')
ylabel("$P\ \ \ (\frac{\mu C}{{cm}^2})$",'Interpreter','latex')

for i=1:size(anHystCurves,2) % Plot anhysteresis curve
    lineHandler = plot(anHystCurves{i}(:,1),anHystCurves{i}(:,2),...
        'Color','k',...
        'LineWidth',1.0,...
        'LineStyle','--',...
        'DisplayName','Anhysteresis curve $\mathcal{A}$'); hold on;
    if(i>1) set(lineHandler,'handleVisibility','off'); end
end
uSat = linspace(-2500,2500,50);
plot(uSat,outputInvTrans(PsatPlus(inputTrans(uSat))),...
    '--r',...    'Color',[150,0,0]/255,...
    'LineWidth',1.2,...
    'DisplayName','$P_{sat}^+$',...
    'HandleVisibility','on');
plot(uSat,outputInvTrans(PsatMinus(inputTrans(uSat))),...
    '--b',...    'Color',[0,0,120]/255,...
    'LineWidth',1.2,...
    'DisplayName','$P_{sat}^-$',...
    'HandleVisibility','on');
plot(uBaseAsc,xBaseAsc,...
    ':g',...
    'LineWidth',1.75,...
    'DisplayName','$\mathcal{Y}_{u_{p+}}$',...
    'HandleVisibility','on');
plot(0,remnantMin,...
    'og','LineWidth',1.25,...
    'markerSize',6,...
    'DisplayName','$\varsigma_{min}$')
plot(0,remnantMax,...
    'xb','LineWidth',1.25,...
    'markerSize',8,...
    'DisplayName','$\varsigma_{max}$')

leg = legend(...
    'Interpreter','latex',...
    'Location','northeast');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% figure
% subplot(3,1,1)
% stem(linspace(0,iter,iter+1), amps(1:iter+1), ...
%     '-b', 'LineWidth', lineWidth); hold on;
% % xlabel('$k$', 'Interpreter', 'Latex');
% ylabel('$w_k$', 'Interpreter', 'Latex');
% xlim([0,iter]);
% ylim([-100, max(amps)+300]);
% 
% subplot(3,1,2)
% stem(linspace(0,iter,iter+1), remnants(1:iter+1), ...
%     '-b', 'LineWidth', lineWidth); hold on;
% plot(linspace(0,iter,1000), linspace(ref,ref,1000), ...
%     '--k', 'LineWidth', lineWidth);
% % xlabel('$k$', 'Interpreter', 'Latex');
% ylabel('$\gamma(w_k,I_k)$', 'Interpreter', 'Latex');
% xlim([0,iter]);
% ylim([min(remnants)-2, max(remnants)+2]);
% 
% subplot(3,1,3)
% stem(linspace(0,iter,iter+1), errors(1:iter+1), ...
%     '-b', 'LineWidth', lineWidth); hold on;
% xlabel('$k$', 'Interpreter', 'Latex');
% ylabel('$\varepsilon_k$', 'Interpreter', 'Latex');
% xlim([0,iter]);
% ylim([min(errors)-1, max(errors)+3]);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

extraIter = 2;
horizon = 2*iter-1;
horizonExtra = horizon+extraIter;
timeVals = [linspace(0,horizonExtra,horizonExtra*samples)]';
inputVals = [reshape(uMat(:,1:horizon),horizon*samples,1);...
                zeros(samples*extraIter,1)];
xMatVals = [reshape(xMat(:,1:horizon),horizon*samples,1);...
                xMat(end,horizon)*ones(samples*extraIter,1)];

figure
subplot(3,1,1)
plot(timeVals, inputVals, '-b', 'LineWidth', lineWidth); hold on;
plot([0:2:horizon]+0.5, controlAmps(1:iter),'or',...
    'LineWidth', lineWidth,...
    'MarkerSize', markerSize-3);
plot([1:2:horizon-1]+0.5, resetAmps(1:iter-1),'og',...
    'LineWidth', lineWidth,...
    'MarkerSize', markerSize-3);
xlabel('$t$', 'Interpreter', 'Latex');
ylabel('$u_\varsigma$', 'Interpreter', 'Latex');
xlim([0,horizonExtra]);
ylim([min(resetAmps)-300, max(controlAmps)+300]);

subplot(3,1,2)
plot(timeVals, xMatVals, '-b', 'LineWidth', lineWidth); hold on;
plot([0:2:horizon]+1.0, remnants(1:iter),'or',...
    'LineWidth', lineWidth,...
    'MarkerSize', markerSize-3);
plot([1:2:horizon-1]+1.0, remnantMin*ones(1,iter-1),'og',...
    'LineWidth', lineWidth,...
    'MarkerSize', markerSize-3);
plot(linspace(0,horizonExtra,1000), linspace(ref,ref,1000), '--k', ...
    'LineWidth', lineWidth);
plot(linspace(0,horizonExtra,1000), remnantMin*ones(1,1000),':g',...
    'LineWidth', lineWidth,...
    'MarkerSize', markerSize-3);
xlabel('$t$', 'Interpreter', 'Latex');
ylabel('$\mathcal{D}(u_\varsigma,y_0)$', 'Interpreter', 'Latex');
xlim([0,horizonExtra]);
ylim([min(xMatVals)-2, max(xMatVals)+2]);

subplot(3,1,3)
stem([1:2:horizon], errors(2:iter+1), 'ob',...
    'MarkerEdgeColor', 'r',...
    'MarkerSize', markerSize-3,...
    'LineWidth', lineWidth); hold on;
xlabel('$k$', 'Interpreter', 'Latex');
ylabel('$\varepsilon_k$', 'Interpreter', 'Latex');
xlim([0,horizonExtra]);
ylim([min(errors)-1, max(errors)+3]);