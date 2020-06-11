val WtoW31 = Word31.fromLargeWord o Word.toLargeWord

fun montecarlopi iterations return_chan randomiser = let
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
    (* CML.send (return_chan,
              (4.0 * ((real (helper 0 iterations randomiser)) /
                      (real iterations)))) *)
    CML.send (return_chan, (helper 0 iterations randomiser))
end

fun experiment (iterations : int) (num_threads : int) : unit = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    val return_chan = CML.channel ()

    fun collect_from_chan 0 sum = sum
      | collect_from_chan count sum = let
          val msg = CML.recv return_chan
      in
          collect_from_chan (count - 1) (sum + msg)
      end

    (* The +1 ensures that this program doesn't do too few iterations *)
    val iters_per_thread : int = Int.quot(iterations, num_threads) + 1
    val _ = Vector.tabulate (num_threads,
                             fn _ => CML.spawn (fn () =>
                                                   montecarlopi iters_per_thread return_chan
                                                                ((Rand.mkRandom (WtoW31 (MLton.Random.rand ()))) ())))
in
    (* TextIO.print ((Real.toString ((collect_from_chan num_threads 0.0) /
                                  (Real.fromInt num_threads))) ^ "\n"); *)
    TextIO.print((Real.toString (4.0 * ((real (collect_from_chan num_threads 0)) /
                                        (real iterations)))) ^ "\n");
    TextIO.print ("Monte Carlo Pi completed succesfully!\n")
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
    val num_threads = valOf (Int.fromString(List.nth(args, 1)))
in
val _ = RunCML.doit (fn () => (experiment iterations num_threads), NONE)
end
