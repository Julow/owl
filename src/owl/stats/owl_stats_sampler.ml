(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2018 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)


let rejection ~m ~proprvs ~proppdf ~pdf nsamples =
  assert (m > 0.);
  let log_m = log m in
  let accept = ref 0 in
  let reject = ref 0 in
  let samples = Array.make nsamples 0. in

  while !accept < nsamples do
    let x = proprvs () in
    let a = log (Owl_stats_dist.std_uniform_rvs ()) in
    let b = (log (pdf x)) -. (log (proppdf x)) -. log_m in
    assert (b < 0.);
    if a < b then (
      samples.(!accept) <- x;
      accept := !accept + 1;
    )
    else reject := !reject + 1
  done;

  samples


let metropolis ?burnin ?thin ~initial ~proprvs ~proppdf ~pdf nsamples =
  let burnin = match burnin with Some a -> a | None -> 1000 in
  let thin = match thin with Some a -> a | None -> 10 in

  let accept = ref 0 in
  let niter = burnin + thin * nsamples in
  let samples = Array.make niter [||] in
  samples.(0) <- Array.copy initial;

  for i = 1 to niter - 1 do
    let x  = samples.(i - 1) in
    let x' = proprvs x in
    let p  = log (pdf x) in
    let p' = log (pdf x') in
    let g  = log (proppdf x x') in
    let g' = log (proppdf x' x) in
    let a  = min 0. (p' -. p +. g -. g') in
    let b =
      if a >= 0. then true
      else if log (Owl_stats_dist.std_uniform_rvs ()) < a then true
      else false
    in
    let x' = if b then x' else Array.copy x in
    if b then accept := !accept + 1;
    samples.(i) <- x'
  done;

  Owl_utils.Array.filteri (fun i _ ->
    (i >= burnin) && (i mod thin = 0)
  ) samples


let gibbs = None


let adaptive_rejection = None