val real_divisor = Math.pow (2.0, Real.fromInt Word.wordSize)

fun wordToBoundedReal w = let
    val wi = Word.toInt w
    val wr = Real.fromInt wi
in
    wr / real_divisor
    (* The construction and use of real_divisor was provided by Yawar Raza via the MLton mailing list (thanks!) *)
end

(* fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) () = let *)
(*     fun helper iteration accumulator = let *)
(* 	val x : real = wordToBoundedReal (MLton.Random.rand ()) *)
(* 	val y : real = wordToBoundedReal (MLton.Random.rand ()) *)
(*     in *)
(* 	case iteration *)
(* 	 of 0 => accumulator *)
(* 	  | iters => let *)
(* 	      val in_target = (x * x) + (y * y) *)
(*               val _ = TextIO.print ("Iters is: " ^ (Int.toString iters) ^ ", in_target is: " ^ (Real.toString in_target) *)
(*                                     ^ ",x is: " ^ (Real.toString x) ^ ",y is: " ^ (Real.toString y) ^ "\n") *)
(* 	  in *)
(* 	      if in_target < 1.0 then *)
(* 		  helper (iters - 1) (accumulator + 1) *)
(* 	      else *)
(* 		  helper (iters - 1) accumulator *)
(* 	  end *)
(*     end *)
(* in *)
(*     SyncVar.iPut (return_ivar, (4.0 * ((real (helper iterations 0)) / (real iterations)))) *)
(* end *)

fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) () = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    fun helper accumulator 0 = accumulator
      | helper accumulator iteration = let
          val x : real = wordToBoundedReal (MLton.Random.rand ())
          val y : real = wordToBoundedReal (MLton.Random.rand ())
          val in_target = (x * x) + (y * y)
          val next_iter = iteration - 1
          val _ = TextIO.print ("next_iter is: " ^ (Int.toString next_iter) ^ ", in_target is: " ^ (Real.toString in_target)  ^ ",x is: " ^ (Real.toString x) ^ ",y is: " ^ (Real.toString y) ^ "\n")
      in
          if in_target < 1.0 then
              helper (accumulator + 1) next_iter
          else
              helper accumulator next_iter
      end
in
    SyncVar.iPut (return_ivar, (4.0 * ((real (helper 0 iterations)) / (real iterations))))
end

fun experiment (iterations : int) (num_threads : int) (still_going : bool ref) () : unit = let
    val iters_per_thread : int = iterations div num_threads
    val return_ivars = Vector.tabulate (num_threads, (fn _ => SyncVar.iVar()))
    val _ = Vector.map (fn return_ivar => CML.spawn (montecarlopi iters_per_thread return_ivar)) return_ivars
    val return_val = Vector.foldl (fn (elem, acc) => acc + (SyncVar.iGet elem)) 0.0 return_ivars
in
    (TextIO.print ("Result is: " ^ (Real.toString return_val) ^ "\n");
            still_going := false)
end

local
    (* val args = CommandLine.arguments() *) (* TODO:  Add command line argument handling *)
    val iterations : int = 10
    val num_threads : int = 1
    val still_going : bool ref = ref true
in
   val _ = (RunCML.doit ((experiment iterations num_threads still_going), NONE);
            (* while !still_going do (); (* Spin-wait for the CML stuff to finish.  This doesn't work... *) *)
            print "All done!\n")
end
