% permanent job spell
% likelihood of spell lasting until t and finishing at t
% pre-probation hazard d0, post-probation hazard d1
% probation duration, p
function z = jspell(t,d0,d1,p)

if t<p
    z = exp(-d0*t)*d0;
else
    z = exp(-d0*p)*exp(-d1*(t-p))*d1;
end

end
