%% OshPark 2.45GHz patch design
% Tom Schucker
clear;

%% Physical constant
c  = physconst('lightspeed');

%% Design Parameters

%center frequency
fc = 2450e6; 

%dialectric constant
er = 4.35;

%Hight of the substrait
h = 1.524e-3; %m 1.524mm

%microstrip width 50ohms
mw50 = 2.685e-3; %m

%microstrip width 100ohms
mw100 = .565e-3; %m

%Length of antenna patch
%L = c/(2*fc*sqrt(er)); %m
L = .0281;

%Width of antenna patch
W = .03;%L; %m

%Length of ground plane
Lg = .050; %2*L;

%Width of ground plane
Wg = .04; %2*W;

%Inset notch width
Nw = mw50*3;

%Inset notch length
Nl = mw50*2;

%% Create antenna primatives
patch = antenna.Rectangle('Length', L, 'Width', W);
groundplane = antenna.Rectangle('Length', Lg, 'Width', Wg);
notch = antenna.Rectangle('Length', Nl, 'Width', Nw, 'Center', [(L/2)-(Nl/2),0]);
microstrip_feed = antenna.Rectangle('Length', Lg/2, 'Width', mw50, 'Center', [(Lg/4),0]);
substrait_material = dielectric('Name','FR4','EpsilonR', er, 'Thickness', h); %dielectric('FR4');

build_patch = (patch-notch) + microstrip_feed;

%% Define the properties of the PCB stack.
basicPatch = pcbStack;
basicPatch.Name = 'Spectrum Buddy Basic Patch';
basicPatch.BoardThickness = h;
basicPatch.BoardShape = groundplane;
basicPatch.Layers = {build_patch,substrait_material,groundplane};
basicPatch.FeedLocations = [Lg/2 0 1 3];
basicPatch.FeedDiameter = mw50/2;
figure
show(basicPatch)
figure;
mesh(basicPatch, 'MaxEdgeLength',2.5e-3,'MinEdgeLength',0.8e-3);

%% Plot the radiation pattern of the basic patch antenna.
figure
pattern(basicPatch, fc)

%% Plot the impedance of the basic patch antenna.
%enumerate frequencies
freqs = linspace(fc-0.05*fc,fc + 0.1*fc,100);

%plot complex impedance
figure
impedance(basicPatch,freqs)

%plot RF s-parameters
S = sparameters(basicPatch, freqs);
figure; 
rfplot(S);

%% Parallel Computation
%plot return loss
% RLparfor = zeros(size(freqs));
% parfor m = 1:100
%     RLparfor(m) = returnLoss(basicPatch, freqs(m));
% end
% figure;
% plot(freqs, RLparfor);

%% PCB GERBER generation
%connector
connector = PCBConnectors.SMAEdge;
connector.SignalLineWidth = mw50;
connector.EdgeLocation = 'east';
connector.ExtendBoardProfile = false;

%pcb service
service = PCBServices.OSHParkWriter;
service.Filename = 'OshPark_2.45GHz_Patch.zip';

%write gerber
PW = PCBWriter(basicPatch,service,connector);
gerberWrite(PW);
