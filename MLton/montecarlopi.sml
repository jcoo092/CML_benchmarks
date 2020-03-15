val real_divisor = Math.pow (2.0, Real.fromInt Word.wordSize)

fun wordToBoundedReal w = let
    val wi = Word.toInt w
    val wr = Real.fromInt wi
in
    wr / real_divisor
    (* The construction and use of real_divisor was provided by Yawar Raza via the MLton mailing list (thanks!) *)
end

fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) () = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    fun helper accumulator 0 = accumulator
      | helper accumulator iteration = let
          val x : real = wordToBoundedReal (MLton.Random.rand ())
          val y : real = wordToBoundedReal (MLton.Random.rand ())
          val in_target = (x * x) + (y * y)
          val next_iter = iteration - 1
          val _ = TextIO.print ("next_iter is: " ^ (Int.toString next_iter) ^ ", in_target is: "
                                ^ (Real.toString in_target)  ^ ",x is: " ^ (Real.toString x)
                                ^ ",y is: " ^ (Real.toString y) ^ "\n")
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
in
    TextIO.print ("Result is: " ^ (Real.toString return_val) ^ "\n")
end

local
    (* val args = CommandLine.arguments() *) (* TODO:  Add command line argument handling *)
    val iterations : int = 100
    val num_threads : int = 10
    val status = RunCML.doit ((experiment iterations num_threads), NONE);
in
   (* val _ = (RunCML.doit ((experiment iterations num_threads), NONE); *)
   (*          while RunCML.isRunning() do (OS.Process.sleep (Time.fromMilliseconds 100); *)
   (*                                       print "isRunning was true!\n"); (* Spin-wait for the CML stuff to finish.  This doesn't work... *) *)
   (*         print "All done!\n") *)
val _ = (while not (OS.Process.isSuccess status) do ();
         print "All done!\n")
end
