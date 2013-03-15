(*

  sampler.ml
  Sampling for probability distributions

*)

type distribution =
  Uniform of float * float  (* low, high *)
| DUniform of int * int     (* low, high *)
| Normal of float * float   (* mean, variance *)
| Bernoulli of float        (* rate *)
| Binomial of int * float   (* number, rate *)
| Exp of float              (* parameter *)
| MVNormal of float array * float array array (* mean, covariance matrix *)

type basic_sampler =
  {
    init: int -> unit;
    sample_unif: float -> float;
    sample_unif1: unit -> float;
  }

type sampler =
  {
    base: basic_sampler;
    sample: distribution -> float;
    samples: distribution -> int -> float list;
  }

let pi = 4.0 *. (atan 1.0)

(** Sampler from standard library (or Core) *)
let stdsmp = { init = Random.init; sample_unif = Random.float;
               sample_unif1 = ( fun () -> Random.float 1.0 ); }

let sample_exp smp param =
  let u = smp.sample_unif1 () in
  -. (log u) /. param   (* X = -log U / p is distributed as Exp(p) *)

let sample_stdnormal_boxmuller smp =
  let u1 = smp.sample_unif1 () in
  let u2 = smp.sample_unif1 () in
  let x1 = (sqrt (-.2.0 *. (log u1))) *. (cos (2.0 *. pi *. u2)) in
  let x2 = (sqrt (-.2.0 *. (log u1))) *. (sin (2.0 *. pi *. u2)) in
  (* (x1, x2) *)
  x1 (* throw away a sample *)

let stdnorm_samples smp num =
  let res = Array.init num (fun i -> sample_stdnormal_boxmuller smp) in
  res


let r_output arr =
  print_string "c(";
  Array.iter (fun n -> print_float n; print_string ", ") arr;
  print_endline ")"

(** Cholesky decomposition. Given a symmetric positive definite matrix A, 
    return a lower-triangular matrix L such that A = LL' *)
let cholesky a = 
  a

let matvec_mult mat vec = 
  let n = Array.length mat in 
  if Array.length vec != n then failwith "matvec_mult: incompatible dimensions"
  else
    let res = Array.create n 0.0 in 
    for i = 1 to n do
      res.(i) <- 0.0;
      for j = 1 to n do 
        res.(i) <- res.(i) +. mat.(i).(j) *. vec.(j)
      done
    done;
    res

(** Makes v1 <- v1 + v2 with v1 and v2 vectors *)
let vector_displace v1 v2 = 
  let n = Array.length v1 in 
  if Array.length v2 != n then failwith "vector_displace: incompatible dimensions"
  else
    for i = 1 to n do
      v1.(i) <- v1.(i) +. v2.(i)
    done

(** Sample from a multivariate normal distribution with mean vector 
    mu and covariance matrix sigma *)
let sample_mvnorm smp mu sigma =
  let n = Array.length mu in         (* dimension of the MV normal *)
  let cholfact = cholesky sigma in
  let nsamples = stdnorm_samples smp n in (* stdnormal samples?? *)
  let res = matvec_mult cholfact nsamples in
  vector_displace res mu;
  res
