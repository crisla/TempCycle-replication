% survival function for 1 completed U spell starting from E
function y = S1e(t,d0,d1,p,l)

x = linspace(0,t,1000);
dx = x(2)-x(1);
Int = jspell(t,d0,d1,p).*(1-exp(-l*(t-x)));

y = 1 - sum(Int)*dx;