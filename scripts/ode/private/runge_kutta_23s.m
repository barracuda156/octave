########################################################################
##
## Copyright (C) 2013-2020 The Octave Project Developers
##
## See the file COPYRIGHT.md in the top-level directory of this
## distribution or <https://octave.org/copyright/>.
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.
##
########################################################################

## -*- texinfo -*-
## @deftypefn  {} {[@var{t_next}, @var{x_next}] =} runge_kutta_23s (@var{fun}, @var{t}, @var{x}, @var{dt})
## @deftypefnx {} {[@var{t_next}, @var{x_next}] =} runge_kutta_23s (@var{fun}, @var{t}, @var{x}, @var{dt}, @var{options})
## @deftypefnx {} {[@var{t_next}, @var{x_next}] =} runge_kutta_23s (@var{fun}, @var{t}, @var{x}, @var{dt}, @var{options}, @var{k_vals})
## @deftypefnx {} {[@var{t_next}, @var{x_next}] =} runge_kutta_23s (@var{fun}, @var{t}, @var{x}, @var{dt}, @var{options}, @var{k_vals}, @var{t_next})
## @deftypefnx {} {[@var{t_next}, @var{x_next}, @var{x_est}] =} runge_kutta_23s (@dots{})
## @deftypefnx {} {[@var{t_next}, @var{x_next}, @var{x_est}, @var{k_vals_out}] =} runge_kutta_23s (@dots{})
##
## This function can be used to integrate a system of ODEs with a given initial
## condition @var{x} from @var{t} to @var{t+dt}, with a Rosenbrock method of
## order (2,3).  All the mathematical formulas are from Shampine, L. F. and
## M. W. Reichelt, "The MATLAB ODE Suite", SIAM Journal on Scientific
## Computing, Vol. 18, 1997, pp. 1–22.
##
## @var{f} is a function handle that defines the ODE: @code{y' = f(tau,y)}.
## The function must accept two inputs where the first is time @var{tau} and
## the second is a column vector of unknowns @var{y}.
##
## @var{t} is the first extreme of integration interval.
##
## @var{x} is the initial condition of the system..
##
## @var{dt} is the timestep, that is the length of the integration interval.
##
## The optional fourth argument @var{options} specifies options for the ODE
## solver.  It is a structure generated by @code{odeset}.  In particular it
## contains the field @var{funarguments} with the optional arguments to be used
## in the evaluation of @var{fun}.
##
## The optional fifth argument @var{k_vals_in} contains the Runge-Kutta
## evaluations of the previous step to use in a FSAL scheme.
##
## The optional sixth argument @var{t_next} (@code{t_next = t + dt}) specifies
## the end of the integration interval.  The output @var{x_next} s the higher
## order computed solution at time @var{t_next} (local extrapolation is
## performed).
##
## Optionally the functions can also return @var{x_est}, a lower order solution
## for the estimation of the error, and @var{k_vals_out}, a matrix containing
## the Runge-Kutta evaluations to use in a FSAL scheme or for dense output.
##
## @seealso{runge_kutta_23}
## @end deftypefn

function [t_next, x_next, x_est, k] = runge_kutta_23s (fun, t, x, dt,
                                                       options = [],
                                                       k_vals = [],
                                                       t_next = t + dt)

  persistent d = 1 / (2 + sqrt (2));
  persistent a = 1 / 2;
  persistent e32 = 6 + sqrt (2);

  ## extra arguments for function evaluator
  if (! isempty (options))
    args = options.funarguments;
  else
    args = {};
  endif

  jacfun = false;
  jacmat = false;
  if (! isempty (options.Jacobian))
    if (ischar (options.Jacobian))
      jacfun = true;
      jac = str2fun (options.Jacobian);
    elseif (is_function_handle (options.Jacobian))
      jacfun = true;
      jac = options.Jacobian;
    elseif (ismatrix (options.Jacobian))
      jacmat = true;
      jac = options.Jacobian;
    else
      error (["ode23s: the jacobian should be passed as a matrix, ", ...
        "a string or a function handle"])
    endif
  endif

  jacpat = false;
  if (! isempty (options.JPattern))
    jacpat = true;
    pattern = logical (options.JPattern);
  endif

  ## Jacobian matrix, dfxpdp
  if (jacmat)
    J = jac;
  elseif (jacfun)
    J = jac (t, x);
  elseif (! jacpat)
    J = __dfxpdp__ (x, @(a) feval (fun, t, a, args{:}), options.RelTol);
  elseif (jacpat)
    J = __dfxpdp__ (x, @(a) feval (fun, t, a, args{:}), options.RelTol, pattern);
  endif

  T = (feval (fun, t + .1 * dt, x) - feval (fun, t, x, args{:})) / (.1 * dt);

  ## Wolfbrandt coefficient
  if (isempty (options.Mass))
    M = speye (length (x));
  else
    M = options.Mass;
  endif
  W = M - dt*d*J;

  if issparse (W)
    [Lw, Uw, Pw, Qw, Rw] = lu  (W);
  else
    [Lw, Uw, Pw] = lu (W);
  endif

  ## compute the slopes
  F(:,1) = feval (fun, t, x, args{:});
  if issparse (W)
    k(:,1) = Qw * (Uw \ (Lw \ (Pw * (Rw \ (F(:,1) + dt*d*T)))));
  else
    k(:,1) = Uw \ (Lw \ (Pw * (F(:,1) + dt*d*T)));
  endif
  F(:,2) = feval (fun, t+a*dt, x+a*dt*k(:,1), args{:});
  if issparse (W)
    k(:,2) = Uw * (Uw \ (Lw \ (Pw * (Rw \ (F(:,2) - M*k(:,1)))))) + k(:,1);
  else
    k(:,2) = Uw \ (Lw \ (Pw * (F(:,2) - M*k(:,1)))) + k(:,1);
  endif

  ## compute the 2nd order estimate
  x_next = x + dt*k(:,2);

  if (nargout >= 3)
    ## 3rd order, needed in error formula
    F(:,3) = feval (fun, t+dt, x_next, args{:});
    if issparse (W)
      k(:,3) = Qw * (Uw \ (Lw \ (Pw * (Rw \ (F(:,3) - e32 * (M*k(:,2) - F(:,2)) - 2 * (M*k(:,1) - F(:,1)) + dt*d*T)))));
    else
      k(:,3) = Uw \ (Lw \ (Pw * (F(:,3) - e32 * (M*k(:,2) - F(:,2)) - 2 * (M*k(:,1) - F(:,1)) + dt*d*T)));
    endif

    ## estimate the error
    err_est = (dt/6) * (k(:,1) - 2*k(:,2) + k(:,3));

    ## FIXME: to use in AbsRel_Norm function I need x_est and not err directly
    x_est = x_next + err_est;
  endif

endfunction


function prt = __dfxpdp__ (p, func, rtol, pattern)

  ## This subfunction was copied 2011 from the OF "optim" package
  ## "inst/private/__dfdp__.m".

  f = func (p)(:);
  m = numel (f);
  n = numel (p);

  diffp = rtol .* ones (n, 1);

  del = ifelse (p == 0, diffp, diffp .* p);
  absdel = abs (del);

  ## double sided interval
  p1 = p + absdel / 2;
  p2 = p - absdel / 2;

  ps = p;
  if (nargin > 3 && issparse (pattern))
    prt = pattern;  # initialize Jacobian
    for j = find (any (pattern, 1))
      ps(j) = p1(j);
      tp1 = func (ps);
      ps(j) = p2(j);
      tp2 = func (ps);
      pattern_nnz = find (pattern(:, j));
      prt(pattern_nnz, j) = (tp1(pattern_nnz) - tp2(pattern_nnz)) / absdel(j);
      ps(j) = p(j);
    endfor
  else
    prt = zeros (m, n); # initialize Jacobian
    for j = 1:n
      ps(j) = p1(j);
      tp1 = func (ps);
      ps(j) = p2(j);
      tp2 = func (ps);
      prt(:, j) = (tp1(:) - tp2(:)) / absdel(j);
      ps(j) = p(j);
    endfor
  endif

endfunction
