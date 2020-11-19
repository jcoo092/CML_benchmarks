(* The two lines below, and the spawnOn function, are taken directly from 
https://github.com/ManticoreProject/benchmark/blob/master/benchmarks/programs/cml-parallelpp/parallel-pp2.pml#L20
as at commit ce3dd22 - many thanks to Kavon Farvadin for pointing me to them *)
(* val vps = VProcExtras.vprocs() *)
val vps = Array.fromList (VProcExtras.vprocs())
(* val nVps = List.length vps *)
val nVps = Array.length vps

(* fun spawnOn (f, id) = VProcExtras.spawnOn f (List.nth(vps, id)) *)

fun spawnOn (f, id) = VProcExtras.spawnOn f (Array.sub(vps, id))

fun spawnOnI (i, f) = let
	val imod = Int.rem(i, nVps)
in
	spawnOn (f, imod)
end

fun distribute_extras total base = let
    val q = Int.quot(total, base)
    val r = Int.rem(total, base)
in
    Array.tabulate (base, fn i => if i < r then q + 1 else q)
end

fun montecarlopi return_chan iterations () = let
    fun helper accumulator 0 = accumulator
      | helper accumulator iteration = let
          val x = Rand.randDouble(0.0, 1.0)
          val y = Rand.randDouble(0.0, 1.0)
          val in_target = (x * x) + (y * y)
          val next_iter = iteration - 1
      in
          if in_target < 1.0 then
              helper (accumulator + 1) next_iter
          else
              helper accumulator next_iter
      end
	val ret_val = helper 0 iterations
in
	(* Print.print ("ret_val is: " ^ (Int.toString ret_val) ^ "\n"); *)
    PrimChan.send (return_chan, ret_val)
end

fun experiment (iterations : int) (num_threads : int) : unit = let
    val return_chan = PrimChan.new ()

    fun collect_from_chan 0 sum = sum
      | collect_from_chan count sum = let
          val msg = PrimChan.recv return_chan
      in
          collect_from_chan (count - 1) (sum + msg)
      end

    val iters_per_thread_arr = distribute_extras iterations num_threads
    (* val _ = Array.map (fn i => spawn
                                    (montecarlopi i return_chan))
                       iters_per_thread_arr *)
   val mcp = montecarlopi return_chan
   val _ = Array.appi (fn (i,n) => spawnOnI (i, mcp n))
			iters_per_thread_arr
in
    Print.print((Double.toString (4.0 *
                                 ((Double.fromInt (collect_from_chan num_threads 0)) /
                                  (Double.fromInt iterations)))) ^ "\n");
    Print.print ("Monte Carlo Pi completed succesfully!\n")
end

val args = CommandLine.arguments()
val iterations = Option.valOf (Int.fromString(List.nth(args, 0)))
val num_threads = Option.valOf (Int.fromString(List.nth(args, 1)))
val _ = RunPar.run (fn () => experiment iterations num_threads)
