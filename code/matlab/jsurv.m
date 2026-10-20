% permanent job spell
% likelihood of spell lasting until t 
% pre-probation hazard d0, post-probation hazard d1
% probation duration, p
function z = jsurv(t,d0,d1,p)

z = exp(-d0*t).*(t<p)+exp(-d0*p)*exp(-d1*(t-p)) .*(t>=p);

end