(* This particular program is heavily based on the dense-matrix-multiply.pml file from the Manticore benchmarks repository *)

(********** Common bits **********)

val min_val = 2
val max_val = 256

fun add (x, y) = x + y

fun dims2 (arr2 : 'a parray parray) = let
	(* val firstIx = PArray.sub (arr2, 0) *)
	val firstIx = arr2 ! 0
in
	(PArray.length arr2, PArray.length firstIx)
end

(* Used to avoid the whole tensor just becoming a bunch of zeros *)
fun rem_or_rand numerator = let
    val rem = Int.rem(numerator, max_val)
in
    if rem = 0 then
        Rand.inRangeInt (min_val, max_val)
    else
        rem
end

fun rem_all_by_max max t = [| PArray.map rem_or_rand u | u in t |]
val ralbm = rem_all_by_max max_val

(* fun randomMatrix (width, height) = [| [| Rand.inRangeInt (min_val, max_val) | i in [| 0 to width |] |] | j in [| 0 to height |] |] *)
fun randomMatrix (width, height) = PArray.tab2D ((0, 1, width), (0, 1, height), fn (_,_) => Rand.inRangeInt (min_val, max_val))

fun elementwiseAddMatrices (t1, t2) = let
	val (t1m, t1n) = dims2 t1
	val (t2m, t2n) = dims2 t2
in
	if t1m = t2m andalso t1n = t2n then
		(* [| [| i + j | i in t1 |] | j in t2 |] *)
		[| [| k + l | k in i, l in j |] | i in t1, j in t2 |]
	else
		raise Fail("Vector sizes do not match for addition")
end

(* Pretty much taken directly from the benchmark program 'dense-matrix-multiply.pml' *)
fun denseMatrixMultiply (m, n) =
let
	fun mvm (n, a) =
			[|  PArray.reduce add 0 [| bi * ai | bi in ni, ai in a |] | ni in n |]
in
		[| mvm (n, mi) | mi in m |]
end

fun sliceOutNewMatrix (lo, up, t) = let (* lo and up are the start and end indices, while t is the tensor *)
(* lo should be inclusive, and up exclusive *)
	val lm::ln::_ = lo
	val um::un::_ = up
	(* val mdiff = um - lm
	val ndiff = un - ln *)
	val (mdiff, ndiff) = (| um - lm, un - ln |)
	val (mrange, nrange) = (| [| lm to um |] , [| ln to un |] |)
in
	if lm <= um andalso ln <= un then
		[| [| (t ! i) ! j | i in mrange |] | j in nrange |]
	else
		raise Fail("an index of lo was greater than one for up")
end

fun transpose (m : 'a parray parray) = let
	val w = PArray.length (m ! 0)
	val h = PArray.length m
	val wRange = [| 0 to (w-1) |]
	val hRange = [| 0 to (h-1) |]
in
	[| [| (m ! i) ! j | i in hRange |] | j in wRange |]
end

(********** Vector-specific bits **********)
fun vector iterations size = let
    val initvector1 = randomMatrix (size, 1)
    val initvector2 = randomMatrix (size, 1)
    fun process_vectors 0 _ _ = ()
      | process_vectors iteration v1 v2 = let
          val next_iter = iteration - 1
          val pluses = ralbm (elementwiseAddMatrices (v1, v2))
          val times = ralbm (sliceOutNewMatrix(
                                           [0,0], [size,1],
                                           (denseMatrixMultiply(v1, (transpose v2)))))
      in
          (* tfiwn2 v1 "v1";
          tfiwn2 v2 "v2";
          tfiwn2 pluses "pluses";
          tfiwn2 times "times"; *)
          process_vectors next_iter pluses times
      end
in
    process_vectors iterations initvector1 initvector2
end


(********** Matrix-specific bits **********)
fun matrixops iterations size = let
    val initmatrix1 = randomMatrix (size, size)
    val initmatrix2 = randomMatrix (size, size)
    fun process_matrices 0 _ _ = ()
      | process_matrices iteration m1 m2 = let
          val next_iter = iteration - 1
          val pluses = ralbm (elementwiseAddMatrices (m1, m2))
          val times = ralbm (denseMatrixMultiply(m1, m2))
      in
          (* tfiwn2 m1 "m1";
          tfiwn2 m2 "m2";
          tfiwn2 pluses "pluses";
          tfiwn2 times "times"; *)
          process_matrices next_iter pluses times
      end
in
    process_matrices iterations initmatrix1 initmatrix2
end

(********** Mixed-specific bits **********)
fun mixed iterations size = let
    val initcolvec = randomMatrix (size, 1)
    val initrowvec = randomMatrix (1, size)
    val initmatrix1 = randomMatrix (size, size)
    fun process_mixed 0 _ _ _ = ()
      | process_mixed iteration colvec rowvec m = let
          val next_iter = iteration - 1
          val next_colvec = ralbm (denseMatrixMultiply(m, colvec))
          val next_rowvec = ralbm (denseMatrixMultiply(rowvec, m))
          val next_matrix = ralbm (denseMatrixMultiply(next_colvec, next_rowvec))
      in
          (* tfiwn2 colvec "colvec";
          tfiwn2 rowvec "rowvec";
          tfiwn2 m "m";
          tfiwn2 timescol "timescol";
          tfiwn2 timesrow "timesrow";
          tfiwn2 nextmat "nextmat"; *)
          process_mixed next_iter next_colvec next_rowvec next_matrix
      end
in
    process_mixed iterations initcolvec initrowvec initmatrix1
end

(********** 'Main' **********)

fun experiment experiment_selection iterations size = 
    (case experiment_selection of
        "vector" => vector iterations size
      | "matrix" => matrixops iterations size
      | "mixed" => mixed iterations size
      | _ => raise Fail("Experiment name not recognised.");
    Print.print(experiment_selection ^ " completed successfully!\n"))

val args = CommandLine.arguments()
val experiment_selection = List.nth(args, 0)
val iterations = Option.valOf (Int.fromString(List.nth(args, 1)))
val size = Option.valOf (Int.fromString(List.nth(args, 2)))
val _ = experiment experiment_selection iterations size
