//======================================
// poison_nk_ar1_attack.mod
//   – includes the +1σ attack shock
//======================================

var ygap pi i rn nu attack;
varexo rn_shk nu_shk atk_shk;

parameters beta kappa phi alpha gamma rstar pistar
           rho_r rho_nu rho_att;

// Calibration
beta    = 0.99;
kappa   = 0.06;
phi     = 1.0;
alpha   = 1.5;
gamma   = 0.5;
rstar   = 0.5/4;
pistar  = 2/4;
rho_r   = 0.8;
rho_nu  = 0.6;
rho_att = 0.8;

model;
  // NKPC
  pi      = beta*pi(+1) + kappa*ygap;
  // IS
  ygap    = ygap(+1) - phi*(i - pi(+1) - rn);
  // AR(1)’s
  rn      = rho_r   * rn(-1)   + rn_shk;
  nu      = rho_nu  * nu(-1)   + nu_shk;
  attack  = rho_att * attack(-1) + atk_shk;     // ← correct lag
  // Taylor rule on perceived gap
  i = rstar + pistar
    + alpha*(pi - pistar)
    + gamma*(ygap + nu + attack);
end;

initval;
  ygap   = 0;    pi     = pistar;
  i      = rstar + pistar;
  rn     = rstar; nu     = 0;
  attack = 0;
end;

steady; check;

shocks;
  var rn_shk;  stderr 0.4;
  var nu_shk;  stderr 0.3;
  var atk_shk; stderr 1;        // include the attack shock here
end;

stoch_simul(order = 1, irf = 16);

