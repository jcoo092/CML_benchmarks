fun wordToBoundedReal w = let
    val wi = Word.toInt w
    val wr = Real.fromInt wi
in
    wr / Real.maxFinite
    (* best as I can tell, the value produced by MLton.Random.rand can vary from 0.0 up to maxFinite.
       Thus, to get a value in the range of 0.0 to 1.0, dividing by maxFinite is likely to work best
       as a simple way to do this.  There could be some loss of precision, but that isn't particularly
       important here *)
end

fun montecarlopi (iterations : int) (return_ivar : real SyncVar.ivar) () = let
    fun helper iterations accumulator = let
	val x : real = wordToBoundedReal (MLton.Random.rand ())
	val y : real = wordToBoundedReal (MLton.Random.rand ())
    in
	case iterations
	 of 0 => accumulator
	  | iters => let
	      val in_target = (x * x) + (y * y)
	  in
	      if in_target < 1.0 then
		  helper (iters - 1) (accumulator + 1)
	      else
		  helper (iters - 1) accumulator
	  end
    end
in
    SyncVar.iPut (return_ivar, (4.0 * ((real (helper iterations 0)) / (real iterations))))
end

fun experiment (iterations : int) (num_threads : int) : unit = let
    val iters_per_thread : int = iterations div num_threads
    val return_ivars = Vector.tabulate (num_threads, (fn _ => SyncVar.ivar()))
    val _ = Vector.app (fn return_ivar => CML.spawn (montecarlopi iters_per_thread return_ivar)) return_ivars
    val return_val = Vector.foldl (fn (elem, acc) => acc + (SyncVar.iGet elem)) 0.0 return_ivars
in
    print (Real.toString return_val)
end

local
    val iterations : int = 10
    val num_threads : int = 1
in
    val _ = experiment iterations num_threads
end
