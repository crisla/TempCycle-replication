clear 

N = 1000;
draw = rand(N,3);
mu1 = draw(:,1);
mu2 = draw(:,2);
a = 0.5 + 0.5*draw(:,3); % a in (0.5,1), 1-a in (0,0.5)

mu = a.*mu1 + (1-a).*mu2;
% between variance
sig2_b = a.*(mu1 - mu).^2  + (1 - a).*(mu2 - mu).^2;
% total variance
sig2_tot = 2*(a.*mu1.^2 + (1-a).*mu2.^2) - mu.^2;

% ratio of between over total
fra = sig2_b./sig2_tot;

% maximum ratio
y = max(fra)

% to illustrate: values of mus and a that generate high fraction
[ draw(fra>y-0.03,1:2) a(fra>y-0.03) fra(fra>y-0.03) ]

