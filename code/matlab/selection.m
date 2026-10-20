clear
close all

P = 6; % number of periods of probation
delta0 = 0.015; % jd rate pre probation
delta1 = 0.015; % jd rate post probation
min_h = 0.;
max_h = 0.15;
mu = 0.025;
sig = 0.02;


N = 100; % size of H set
H = linspace(min_h,max_h,N);
% choice of underlying distribution: 1 for uniform, 2 for normal
ch=2 ;
if ch==1
    dh = makedist('uniform',min_h,max_h);
    fprintf('choice of functional form for underlying distribution: uniform \n')
else
    dh = makedist('normal','mu',mu,'sigma',sig);
    fprintf('choice of functional form for underlying distribution: normal \n')
end
mass_h = pdf(dh,H)/sum(pdf(dh,H));
cdf_h = cumsum(mass_h);

T = 600 ; % sample time range
% probability of full cycle delta then h within T given h
% Pcond = 1 - exp(-H*T) - H.*exp(-delta*T).*(1-exp(-(H-delta)*T))./(H-delta);

P_1spell_e = zeros(1,N);
P_2spell_e = zeros(1,N);

for i=1:N
    P_1spell_e(i) = 1-S1e(T,delta0,delta1,P,H(i));
    P_2spell_e(i) = P2e(T,delta0,delta1,P,H(i));
end

% density of h given one or two full cycles within T (starting from E) 
cond_dens1 = P_1spell_e.*mass_h;
cond_dens1 = cond_dens1/sum(cond_dens1);
cond_dens2 = P_2spell_e.*mass_h;
cond_dens2 = cond_dens2/sum(cond_dens2);

% mean and variance of both distributions
m_pop = sum(mass_h.*H);
s_pop = sqrt(sum(mass_h.*H.^2)-m_pop^2);
m_sel1 = sum(cond_dens1.*H);
s_sel1 = sqrt(sum(cond_dens1.*H.^2)-m_sel1^2);
m_sel2 = sum(cond_dens2.*H);
s_sel2 = sqrt(sum(cond_dens2.*H.^2)-m_sel2^2);

fprintf('number of periods: %4.2f\n',T)
fprintf('mean and std dev of underlying population: %4.3f, %4.4f \n',m_pop,s_pop)
fprintf('mean and std dev of selected sample on 1 spell: %4.3f, %4.4f \n',m_sel1,s_sel1)
fprintf('mean and std dev of selected sample on 2 spells: %4.3f, %4.4f \n',m_sel2,s_sel2)

figure
plot(H,P_1spell_e,'--b',H,P_2spell_e,'-r')
title('probability of having completed one and two full cycle(s) in T vs h')

figure
plot(cdf_h,P_2spell_e,'-r')
title('probability of having completed two full cycle in T vs percentile in underlying distribution')
xlim([0 1])

figure
plot(H,mass_h,'-k',H,cond_dens1,'--g',H,cond_dens2,'--r')
title('underlying distribution (black), selected on 1 spell (green) and selected on 2 spells distributions (red)')

x = linspace(0,100,100);
figure
plot(x,jsurv(x,delta0,delta1,P))
title('survival function of permanent job spell')
