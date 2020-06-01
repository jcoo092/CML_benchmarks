(* fun run_thread iteration thread_num () = let
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
end *)

(********** Common bits **********)

fun mkRando min max = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
                               val randsArr = Array.array()
    fun rando () = let
        val x = MLton.Random.rand ()
        val q = PackW
    in
        x
    end
in
    rando
end

(********** Vector-specific bits **********)

(********** Matrix-specific bits **********)

(********** 'Main' **********)

fun experiment experiment_selection iterations size () = let
in
    case experiment_selection of
        "vector" => vector iterations size
      | "matrix" => matrix iterations size
      | "mixed" => mixed iterations size
      | _ => raise Fail("Experiment name not recognised.");
    TextIO.print(experiment_selection ^ " completed successfully!\n")
end

local
    val args = CommandLine.arguments()
    val experiment_selection = List.nth(args, 0)
    val iterations = valOf (Int.fromString(List.nth(args, 1)))
    val size = valOf (Int.fromString(List.nth(args, 2)))
in
val _ = RunCML.doit ((experiment experiment_selection iterations size), NONE)
end
