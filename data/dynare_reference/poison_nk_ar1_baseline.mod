//======================================
// poison_nk_ar1_baseline.mod
//   – only natural‐rate & noise shocks
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
  attack  = rho_att * attack(-1) + atk_shk;
  // Taylor rule on perceived gap = ygap + nu + attack
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
  // no atk_shk here → attack bias gets zero shock in baseline
end;

stoch_simul(order = 1, irf = 16);

