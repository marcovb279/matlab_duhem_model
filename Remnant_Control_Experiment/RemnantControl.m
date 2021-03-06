close all
clc

% Paremeters
K0 = 100;
inputMax = 1400;
inputMin = -1400;
remnantMax = 20;
remnantMin = 0;
inputSamples = 1000;
errorThreshold = 0.001;
iterationLimit = 1000;

% Get scales if exist
inputScale = 1;
outputScale = 1;
inputShift = 0;
outputShift = 0;
if(exist('dataHandler','var'))
    inputScale = dataHandler.inputScale;
    outputScale = dataHandler.outputScale;
    inputShift = dataHandler.inputShift;
    outputShift = dataHandler.outputShift;
end
inputTrans = @(u) (u+inputShift)*inputScale;
outputTrans = @(y) (y+outputShift)*outputScale;
inputInvTrans  = @(u) u/inputScale-inputShift;
outputInvTrans = @(y) y/outputScale-outputShift;

% Control objective and initial pulse amp
% Remnant max reachable: -0.33, Remnant min reachable: -0.83531
ref = max([min([18, ...
                remnantMax]),remnantMin]);
initialPulse = max([min([220, ...
                inputMax]),inputMin]);

disp(['Target Output: ', num2str(ref)])
disp(['Error Threshold: ', num2str(errorThreshold)])

% Video parameterscl
videoName = 'video.avi';
videoWidth = 720;
videoHeight = 480;

% Plot parameters
refMarkerSize = 8;
lineWidth = 1.2;

% Figure initialization
fig = figure; axHandler = axes(); hold on;
plot(axHandler,... % Plot original data
    inputInvTrans(dataHandler.inputSeq),...
    outputInvTrans(dataHandler.outputSeq),...
    '-g', ...
    'LineWidth', lineWidth,...
    'DisplayName','Experimental data');
plot(axHandler,... % Plot simulated data
    dataHandlerSim.inputSeq,...
    dataHandlerSim.outputSeq,...
    '-k', ...
    'LineWidth', lineWidth,...
    'DisplayName','Duhem model');
if(exist('PsatPlus','var')) % Plot saturations
    uSat = linspace(-3000,3000,3000);
    plot(uSat,outputInvTrans(PsatPlus(inputTrans(uSat))),...
        'Color','r',...
        'LineWidth',1.2,...
        'DisplayName','$P_{sat}^+$',...
        'HandleVisibility','on');
    plot(uSat,outputInvTrans(PsatMinus(inputTrans(uSat))),...
        'Color','b',...
        'LineWidth',1.2,...
        'DisplayName','$P_{sat}^-$',...
        'HandleVisibility','on');
end
for i=1:size(anHystCurves,2) % Plot anhysteresis curve
    lineHandler = plot(axHandler,...
        anHystCurves{i}(:,1),anHystCurves{i}(:,2),...
        'Color','k',...
        'LineWidth',1.0,...
        'LineStyle','--',...
        'DisplayName','Anhysteresis curve $\mathcal{A}$'); hold on;
    if(i>1) set(lineHandler,'handleVisibility','off'); end
end
xlim([inputMin-0.05*(inputMax-inputMin)...
    inputMax+0.05*(inputMax-inputMin)]);
ylim([remnantMin-0.45*(remnantMax-remnantMin)...
    remnantMax+0.45*(remnantMax-remnantMin)]);

% Plotting parameters
hPad = 0.1; vPad = 0.1; 
minHPad = 0.1; minVPad = 0.1; 
autoAdjust = false;

% Loop Initialization
remnants = 5;
errors = ref-remnants;
inputAmps = initialPulse;
iter = 1;
inputs = [];
outputs = [];

% Plot initial and final points in phase plot
plot(axHandler,0,remnants,'bo',...
    'LineWidth',1.5,...
    'markerSize',7,...
    'HandleVisibility','off');
plot(axHandler,0,ref,'bx',...
    'LineWidth',1.5,...
    'markerSize',8,...
    'HandleVisibility','off');

% Create animated line handlers
anLineHand1 = animatedline(axHandler,...
    'LineWidth',1.2,...
    'Color','blue',...,
    'DisplayName','Duhem model',...
    'HandleVisibility','off');
anLineHand2 = animatedline(axHandler,...
    'LineWidth',1.2,...
    'Color','magenta',...,
    'DisplayName','Convex output',...
    'HandleVisibility','off');

% Legend
leg = legend(...
    'Interpreter','latex',...
    'Location','southeast');

% Video initialization
% videoWriter = VideoWriter(videoName);
% open(videoWriter);
while(true)
    % Print iteration number
    disp('-------------------------')
    disp(['Iteration: ', num2str(iter)])
    disp(['Pulse Amplitude: ', num2str(inputAmps(end))])
    
    % Generate input signal
    [uVec, tVec] = generateInputSignal(inputAmps(end), inputSamples);
    duVec = [0;diff(uVec)./diff(tVec)];
    output = zeros(inputSamples, 1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    odeOutFunc = @(tq,xq,flag)odeDrawing(tq,xq,flag,...
        tVec,uVec,duVec,...
        autoAdjust,hPad,vPad,minHPad,minVPad,...
        anLineHand1,...
        anLineHand2);
    [tTime,xTime] = ode113(...
        @(tq,xq)odeModel(tq,xq,tVec,uVec,duVec),...
        tVec,remnants(end,end),...
        odeset(...
            'OutputFcn',odeOutFunc,...
            'NormControl','off',...
            'Reltol',1e-5,...
            'AbsTol',1e-6,...
            'Refine',1,...
            'MaxStep',10,...
            'Stats','on'));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    inputs = [inputs, uVec(:)];
    outputs = [outputs, xTime(:)];
    
    % Save iteration params and stats
    remnants = [remnants, xTime(end)];
    errors = [errors, (ref-xTime(end))];
    
    % Update pulse value for next iteration
%     if(iter==1)
%     elseif(iter==2)
%     else
%     end
    deltaRemn = remnants(end)-remnants(end-1);
%     K0 = sign(deltaRemn);
    inputAmps = [inputAmps, inputAmps(end)+K0*errors(end)-K0*deltaRemn];

    % Print final output and error
    disp(['Final Output: ', num2str(remnants(end))])
    disp(['Error: ', num2str(errors(end))])
    
    % Break cycle condition
    if abs(errors(end))<=errorThreshold
        disp('-------------------------')
        disp('Error threshold achieved')
        disp('-------------------------')
        break
    elseif iter>=iterationLimit
        disp('-------------------------')
        disp('Iterations limit achieved!')
        disp('-------------------------')
        break
    end
    
    % Update iteration counter
    iter = iter+1;

end

% Close video
% close(videoWriter);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to generate input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [signal, times] = generateInputSignal(pulseAmp, numSamples)
    pointTimes = [0; 0.5; 1.0];
    pointSignal = [0; pulseAmp; 0];
    times = linspace(0, pointTimes(end), numSamples);
    signal = interp1(pointTimes, pointSignal, times);
    
    times = times(:);
    signal = signal(:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxiliary functions for Ode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = odeDrawing(tq,xq,flag,...
    tVec,uVec,duVec,...
    autoAdjust,hPad,vPad,minHPad,minVPad,...
    anLineHand1,...
    anLineHand2)

%     conv = @(x) 0.2*(0.7*x.^2 - 2*x - 10);
    if strcmp(flag,'init')
        [uq,duq] = odeuVecduVecSolver(tq(1),tVec,uVec,duVec);
        addpoints(anLineHand1,uq,xq(1,:));
%         addpoints(anLineHand2,uq,conv(xq(1,:)));
    elseif strcmp(flag,'done')
    else
        [uq,duq] = odeuVecduVecSolver(tq,tVec,uVec,duVec);
        addpoints(anLineHand1,uq,xq);
%         addpoints(anLineHand2,uq,conv(xq));
    end
    if(autoAdjust)
        autoAdjustPlot(anLineHand1,hPad,vPad,minHPad,minVPad);
    end
    drawnow limitrate;
%     drawnow;
    output = 0;
end

function autoAdjustPlot(anLineHand,hPad,vPad,minHPad,minVPad)
    axesHand = get(anLineHand,'Parent');
    [uVec,yVec] = getpoints(anLineHand);
    uMin = min(uVec); uMax = max(uVec); uRange = uMax-uMin;
    xlim(axesHand,[ uMin-max([uRange*hPad,minHPad]),...
                    uMax+max([uRange*hPad,minHPad]) ]);
    yMin = min(yVec); yMax = max(yVec); yRange = yMax-yMin;
    ylim(axesHand,[ yMin-max([yRange*vPad,minVPad]),...
                    yMax+max([yRange*vPad,minVPad]) ]);
end

function dyq = odeModel(tq,xq,tVec,uVec,duVec)
    persistent duhemModel
    if isempty(duhemModel)
        f1 = evalin('base','f1');
        f2 = evalin('base','f2');
        duhemModel = DuhemModel(f1,f2);
    end
    [uq,duq] = odeuVecduVecSolver(tq,tVec,uVec,duVec);
    dyq = duhemModel.getdydt(uq,xq,duq);
end

function [uq,duq] = odeuVecduVecSolver(tq,tVec,uVec,duVec)
    uq = interp1(tVec,uVec,tq);
    duq = interp1(tVec,duVec,tq);
end