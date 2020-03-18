val WtoW31 = Word31.fromLargeWord o Word.toLargeWord

fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) (randomiser: Rand.rand) () = let
    fun helper accumulator 0 _ = accumulator
      | helper accumulator iteration rando = let
          val first_rand = Rand.random rando
          val x = Rand.norm first_rand
          val second_rand = Rand.random first_rand
          val y = Rand.norm second_rand
          val in_target = (x * x) + (y * y)
          val next_iter = iteration - 1
      in
          if in_target < 1.0 then
              helper (accumulator + 1) next_iter (Rand.random second_rand)
          else
              helper accumulator next_iter (Rand.random second_rand)
      end
in
    SyncVar.iPut (return_ivar, (4.0 * ((real (helper 0 iterations randomiser)) / (real iterations))))
end

fun experiment (iterations : int) (num_threads : int) () : unit = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    val iters_per_thread : int = iterations div num_threads
    val return_ivars = Vector.tabulate (num_threads, (fn _ => SyncVar.iVar()))
    val threads = Vector.map (fn return_ivar => CML.spawn (montecarlopi iters_per_thread return_ivar
                                                                       ((Rand.mkRandom (WtoW31 (MLton.Random.rand ()))) ())
                                                                        )) return_ivars
    val return_val = Vector.foldl (fn (elem, acc) => acc + (SyncVar.iGet elem)) 0.0 return_ivars
    val final_pi_estimate = return_val / (Real.fromInt num_threads)
in
    TextIO.print ((Real.toString final_pi_estimate) ^ "\n")
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
    val num_threads = valOf (Int.fromString(List.nth(args, 1)))
in
    val _ = RunCML.doit ((experiment iterations num_threads), NONE)
end
