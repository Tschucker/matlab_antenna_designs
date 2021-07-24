%% PCBWay Small Vivaldi Design 2GHz to 6GHz
% Tom Schucker
clear;

%% Initial Vivaldi Design Parameters for Matlab antenna default vivaldi
Lgnd = 45e-3*2;
Wgnd = 40e-3*2;
Ls = 5e-3*2;
Ltaper = 28.5e-3*2;
Wtaper = 39.96e-3*2;
s = 0.4e-3*2;
d = 5e-3*2;
Ka = (1/Ltaper)*(log(Wtaper/s)/log(exp(1)));

vivaldiant = vivaldi('TaperLength',Ltaper, 'ApertureWidth', Wtaper,     ...
                     'OpeningRate', Ka,'SlotLineWidth', s,              ...
                     'CavityDiameter',d,'CavityToTaperSpacing',Ls,      ...
                     'GroundPlaneLength', Lgnd, 'GroundPlaneWidth', Wgnd,...
                     'FeedOffset',-10e-3);
figure
show(vivaldiant);
vivaldiant.FeedOffset = -14e-3;
ewant = pcbStack(vivaldiant);
topLayer = ewant.Layers{1};
figure
show(topLayer)

%% Remove Matlab Vivaldi Default Feed
cutout = antenna.Rectangle('Length',1e-3,'Width',.4e-3*2,'Center',[-0.014,0]);
topLayer = topLayer-cutout;
figure;
show(topLayer);

%% Design Parameters for New Feed
L1 = 8e-3*2;
L2 = 4.1e-3*2;
L3 = 9.1e-3*2;
W1 = 1.5e-3;
W2 = 1e-3;
W3 = 0.75e-3;
H = 1.524e-3;
fp = 11.2e-3*2;
th = 90;
patch1 = antenna.Rectangle('Length',L1,'Width',W1,...
                           'Center',[-(Lgnd/2 - L1/2), -(Wgnd/2 - fp - W1/2)],...
                           'NumPoints', [10,2,10,2]);
patch2 = antenna.Rectangle('Length',L2,'Width',W2,...
                           'Center',[-(Lgnd/2 - L1 - L2/2), -(Wgnd/2 - fp - W1/2)],...
                           'NumPoints', [5,2,5,2]);
patch3 = antenna.Rectangle('Length',W3,'Width',L3,...
                           'Center',[-(Lgnd/2 - L1 - L2 - W3/2), -(Wgnd/2 - fp - W1/2 + W2/2- L3/2)],...
                           'NumPoints', [2,10,2,10]);
                       
Bowtie = em.internal.makebowtie(8.55e-3, W3, th, [0 0 0],'rounded',20);
rotatedBowtie = em.internal.rotateshape(Bowtie,[0 0 1],[0 0 0],90);
p = antenna.Polygon('Vertices', rotatedBowtie');

radialStub = translate(p, [-(Lgnd/2 - L1 - L2 - W3/2) -(Wgnd/2 - fp - W1/2 + W2/2- L3) 0]);

bottomLayer = patch1+patch2+patch3+radialStub;
figure;
show(bottomLayer);

%% Create Antenna PCB Stack
boardShape = antenna.Rectangle('Length',Lgnd,'Width',Wgnd);
figure;
hold on;
plot(topLayer)
plot(bottomLayer)
grid on

substrate = dielectric('Name','FR4','EpsilonR', 4.15, 'Thickness', H);

vivaldi_Notch = pcbStack;
vivaldi_Notch.Name = 'vivaldiNotch';
vivaldi_Notch.BoardThickness = H;
vivaldi_Notch.BoardShape = boardShape;
vivaldi_Notch.Layers = {topLayer,substrate,bottomLayer};
vivaldi_Notch.FeedLocations = [-(Lgnd/2), -(Wgnd/2 - fp - W1/2), 1, 3];
vivaldi_Notch.FeedDiameter = W1/2;
figure;
show(vivaldi_Notch);
figure;
mesh(vivaldi_Notch, 'MaxEdgeLength',10e-3);

%% Plot the radiation pattern of the Vivaldi antenna over a few key frequencies
% figure
% pattern(vivaldi_Notch, 0.6e9)
% figure
% pattern(vivaldi_Notch, 1.65e9)
figure
pattern(vivaldi_Notch, 2.45e9)
% figure
% pattern(vivaldi_Notch, 3e9)
% figure
% pattern(vivaldi_Notch, 5.8e9)

%% Radiation pattern progression
% radfig = figure;
% radfig.Visible = 'off';
% rad_freqs = 0.6e9:0.05e9:6e9;
% loops = length(rad_freqs);
% rad_movie(loops) = struct('cdata',[],'colormap',[]);
% frame_count = 1;
% 
% for i = rad_freqs
%     pattern(vivaldi_Notch, i)
%     drawnow
%     rad_movie(frame_count) = getframe;
%     frame_count = frame_count + 1;
% end
% radfig.Visible = 'on';
% movie(rad_movie);

%% Plot RF S-parameters
freq = linspace(.6e9, 3.0e9,100);
tic
s_model = sparameters(vivaldi_Notch, freq);
s_time = toc
figure;
rfplot(s_model);

%% Parallel computation
%plot return loss
% RLparfor = zeros(size(freq));
% tic
% parfor m = 1:30
%     RLparfor(m) = returnLoss(vivaldi_Notch, freq(m));
%     m
% end
% par_time = toc
% figure;
% plot(freq, RLparfor);

%% Plot Current Distribution
% figure;
% current(vivaldi_Notch,0.8e9);

%% PCB GERBER generation
%connector
connector = PCBConnectors.SMAEdge;
connector.SignalLineWidth = W1;
connector.EdgeLocation = 'west';
connector.ExtendBoardProfile = false;

%pcb service
service = PCBServices.OSHParkWriter;
service.Filename = 'PCBWay_small_2to6ghz_vivaldi.zip';

%flip for connector, Matlab fix this!!!!!
vivaldi_flipNotch = pcbStack;
vivaldi_flipNotch.Name = 'vivaldiNotch';
vivaldi_flipNotch.BoardThickness = H;
vivaldi_flipNotch.BoardShape = boardShape;
vivaldi_flipNotch.Layers = {bottomLayer,substrate,topLayer};
vivaldi_flipNotch.FeedLocations = [-(Lgnd/2)+6e-3, -(Wgnd/2 - fp - W1/2), 1];
vivaldi_flipNotch.FeedDiameter = W1/2;
figure;
show(vivaldi_flipNotch);

%write gerber
gerberWrite(vivaldi_flipNotch,service,connector);