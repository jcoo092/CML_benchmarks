val real_divisor = Math.pow (2.0, Real.fromInt Word.wordSize)

fun wordToBoundedReal w = let
    val wi = Word.toIntX w
    val wr = Real.fromInt wi
in
    (wr / real_divisor) + 0.5
    (* The construction and use of real_divisor was provided by Yawar Raza via the MLton mailing list (thanks!) *)
    (* I'm not sure why I need the extra + 0.5 there, but without the results I get range from ~0.5 to 0.5,
       whereas with it they range correctly from 0.0 to 1.0 *)
end

fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) () = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    fun helper accumulator 0 = accumulator
      | helper accumulator iteration = let
          val x : real = wordToBoundedReal (MLton.Random.rand ())
          val y : real = wordToBoundedReal (MLton.Random.rand ())
          val in_target = (x * x) + (y * y)
          val next_iter = iteration - 1
      in
          if in_target < 1.0 then
              helper (accumulator + 1) next_iter
          else
              helper accumulator next_iter
      end
in
    SyncVar.iPut (return_ivar, (4.0 * ((real (helper 0 iterations)) / (real iterations))))
end

fun experiment (iterations : int) (num_threads : int) () : unit = let
    val iters_per_thread : int = iterations div num_threads
    val return_ivars = Vector.tabulate (num_threads, (fn _ => SyncVar.iVar()))
    val threads = Vector.map (fn return_ivar => CML.spawn (montecarlopi iters_per_thread return_ivar)) return_ivars
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
