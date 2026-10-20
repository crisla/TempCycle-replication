% survival function for 2 completed U spells starting from E
function y = P2e(t,d0,d1,p,l)

x = linspace(0,t,1000);
dx = x(2)-x(1);


factor1_vec = zeros(1000,1);
factor3_vec = zeros(1000,1);

for i=1:1000
    factor1_vec(i) = S1e(x(i),d0,d1,p,l); % survival function 1 spell to x
    factor3_vec(i) = 1-S1e(t-x(i),d0,d1,p,l); % 1 - survival function 1 spell within t-x
end

factor2_vec = (factor1_vec(2:end)-factor1_vec(1:end-1))/dx;
factor2_vec = [factor2_vec(1) ; factor2_vec];
factor2_vec = -factor2_vec./factor1_vec; % hazard rate of survival function 1 spell

Int = factor1_vec.*factor2_vec.*factor3_vec;
y = sum(Int)*dx;