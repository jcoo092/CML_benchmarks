(*#showBasis "../../../tensor/tensor.basis"*)

(********** Common bits **********)

(* val tfiwn2 = TensorFile.intTensorWriteWithName2 TextIO.stdOut *)

val max_val = 256
val max_val_word = Word.fromInt max_val

fun rand_from_min_to_max min = let
    val randWord = MLton.Random.rand ()
    val modWord = Word.mod(randWord, max_val_word)
    val intModWord = Word.toInt modWord
in
    if intModWord < min then
        rand_from_min_to_max min
    else
        intModWord
end

fun rem_or_rand numerator = let
    val rem = Int.mod(numerator, max_val)
in
    if rem = 0 then
        rand_from_min_to_max 2
    else
        rem
end

fun rem_all_by_256 t = Tensor.map rem_or_rand t

(* I really hate generating random tensors this way, but it's the easiest way to do it right now... *)
fun randomTensor size = rem_all_by_256 (ITensor.tabulate (size, fn _ => INumber.zero))

(********** Vector-specific bits **********)
fun vector iterations size = let
    val initvector1 = randomTensor [size, 1]
    val initvector2 = randomTensor [size, 1]
    fun process_vectors 0 _ _ = ()
      | process_vectors iteration v1 v2 = let
          val next_iter = iteration - 1
          val pluses = rem_all_by_256 (ITensor.+(v1, v2))
          val times = rem_all_by_256 (TensorSlice.sliceOutNewTensor'(
                                           [0,0], [size,1],
                                           (ITensor.dot(v1, (ITensor.transpose v2)))))
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
    val initmatrix1 = randomTensor [size, size]
    val initmatrix2 = randomTensor [size, size]
    fun process_matrices 0 _ _ = ()
      | process_matrices iteration m1 m2 = let
          val next_iter = iteration - 1
          val pluses = rem_all_by_256 (ITensor.+ (m1, m2))
          val times = rem_all_by_256 (ITensor.dot(m1, m2))
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
    val initcolvec = randomTensor [size, 1]
    val initrowvec = randomTensor [1, size]
    val initmatrix1 = randomTensor [size, size]
    fun process_mixed 0 _ _ _ = ()
      | process_mixed iteration colvec rowvec m = let
          val next_iter = iteration - 1
          val next_colvec = rem_all_by_256 (ITensor.dot(m, colvec))
          val next_rowvec = rem_all_by_256 (ITensor.dot(rowvec, m))
          val next_matrix = rem_all_by_256 (ITensor.dot(next_colvec, next_rowvec))
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

fun experiment experiment_selection iterations size = let
in
    case experiment_selection of
        "vector" => vector iterations size
      | "matrix" => matrixops iterations size
      | "mixed" => mixed iterations size
      | _ => raise Fail("Experiment name not recognised.");
    TextIO.print(experiment_selection ^ " completed successfully!\n")
end

local
    val args = CommandLine.arguments()
    val experiment_selection = List.nth(args, 0)
    val iterations = valOf (Int.fromString(List.nth(args, 1)))
    val size = valOf (Int.fromString(List.nth(args, 2)))
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
in
val _ = experiment experiment_selection iterations size
end
