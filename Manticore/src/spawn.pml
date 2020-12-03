(* fun run_thread iteration thread_num cv = let
    val output = "I am child thread " ^ (Int.toString(thread_num)) ^
                 " of iteration " ^ (Int.toString(iteration)) ^ ".\n"
in
    Print.print(output);
    CVar.signal cv
end *)

fun run_thread iteration thread_num cv = CVar.signal cv

fun do_spawn iterations num_threads = let
    fun run_spawn 0 = Print.print("Spawn completed successfully!\n")
      | run_spawn iteration  = let
          val next_iter = iteration - 1
          (* val thds = Array.tabulate (num_threads,
                                      fn i => spawn(run_thread iteration i))
          val joinThds = Array.map (fn t => CML.joinEvt t) thds *)
          val cvs = Array.tabulate (num_threads, fn i => (i, CVar.new ()) )
          val thds = Array.app (fn (i, cv) => spawn (run_thread iteration i cv)) cvs
      in
          Array.app (fn (_, cv) => CVar.wait cv) cvs;
          (* Print.print("Finished this iteration!\n"); *)
          run_spawn next_iter
      end
in
    run_spawn iterations
end

fun experiment iterations num_threads () = do_spawn iterations num_threads

val args = CommandLine.arguments()
val iterations = Option.valOf (Int.fromString(List.nth(args, 0)))
val num_threads = Option.valOf (Int.fromString(List.nth(args, 1)))
val _ = RunSeq.run (experiment iterations num_threads)
