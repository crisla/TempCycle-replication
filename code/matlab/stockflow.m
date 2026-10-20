lambda = 0.06

d = 0:1:72;
Si = exp(-lambda*d);
Su = exp(-lambda*d).*(lambda*d+1);

figure
plot(d,Si,'-k',d,Su,'--b')

