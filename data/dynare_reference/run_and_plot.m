% run_and_plot.m

clear; clc; close all;

%% 1) Rerun Dynare and dump its full output
dynare poison_nk_ar1.mod noclearall

%% 2) Nicely print just the steady‐state vector
fprintf('\n===== Steady-State Results =====\n');
names = cellstr( deblank( M_.endo_names ) );
ss    = oo_.steady_state;

for idx = 1:length(ss)
    fprintf('%-8s = %12.6f\n', names{idx}, ss(idx));
end

%% 3) Extract IRFs
h  = 0:5;  % quarters 0…5

yb = oo_.irfs.ygap_nu_shk(1:6);      % output‐gap → noise
ya = oo_.irfs.ygap_atk_shk(1:6);     % output‐gap → attack

ib = oo_.irfs.i_nu_shk(1:6)   * 100; % policy rate → noise (bp)
ia = oo_.irfs.i_atk_shk(1:6) * 100;  % policy rate → attack (bp)

pb = oo_.irfs.pi_nu_shk(1:6)  * 400; % inflation → noise (annualized pp)
pa = oo_.irfs.pi_atk_shk(1:6) * 400; % inflation → attack (annualized pp)

%% 4) Plot all three panels in one figure
figure('Position',[100,100,600,900]); clf;

% ---- Panel 1: True Output‐Gap IRF ----
subplot(3,1,1);
plot(h, yb,'k--o','LineWidth',1.2,'MarkerSize',6); hold on;
plot(h, ya,'r-^','LineWidth',1.5,'MarkerSize',6); hold off;
xlim([0 5]);
% scalar min across both series:
minYG = min([yb, ya])*1.1;
ylim([minYG, 0]);
title('True Output‐Gap IRF');
ylabel('Percentage points');
legend('Noise','Attack','Location','northeast');

% ---- Panel 2: Policy Rate IRF ----
subplot(3,1,2);
plot(h, ib,'k--o','LineWidth',1.2,'MarkerSize',6); hold on;
plot(h, ia,'r-^','LineWidth',1.5,'MarkerSize',6); hold off;
xlim([0 5]);
% 2‐element y‐limits spanning both series:
minPR = min([ib, ia])*1.1;
maxPR = max([ib, ia])*1.1;
ylim([minPR, maxPR]);
title('Policy Rate IRF');
ylabel('Basis points');
legend('Noise','Attack','Location','northeast');

% ---- Panel 3: Inflation IRF (annualized) ----
subplot(3,1,3);
plot(h, pb,'k--o','LineWidth',1.2,'MarkerSize',6); hold on;
plot(h, pa,'r-^','LineWidth',1.5,'MarkerSize',6); hold off;
xlim([0 5]);
minPI = min([pb, pa])*1.1;
maxPI = max([pb, pa])*1.1;
ylim([minPI, maxPI]);
title('Inflation IRF (annualized)');
ylabel('Percentage points');
xlabel('Quarter');
legend('Noise','Attack','Location','northeast');

%% 5) Save combined figure
print -dpng irf_all_panels.png

