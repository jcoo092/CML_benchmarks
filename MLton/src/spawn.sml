fun run_thread iteration thread_num () = let
    (* val output = "I am child thread " ^ (Int.toString(thread_num)) ^
                 " of iteration " ^ (Int.toString(iteration)) ^ ".\n" *)
in
    (* TextIO.print(output); *)
    ()
end


fun spawn iterations num_threads = let
    fun run_spawn 0 = TextIO.print("Spawn completed successfully!\n")
      | run_spawn iteration  = let
          val next_iter = iteration - 1
          val thds = Vector.tabulate (num_threads,
                                      fn i => CML.spawn(run_thread iteration i))
          val joinThds = Vector.map (fn t => CML.joinEvt t) thds
      in
          Vector.app (fn evt => CML.sync evt) joinThds;
          (* TextIO.print("Finished this iteration!\n"); *)
          run_spawn next_iter
      end
in
    run_spawn iterations
end

fun experiment iterations num_threads () = let
in
    spawn iterations num_threads
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
    val num_threads = valOf (Int.fromString(List.nth(args, 1)))
in
val _ = RunCML.doit ((experiment iterations num_threads), NONE)
end
