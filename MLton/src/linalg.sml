(*#showBasis "../../../tensor/tensor.basis"*)

(********** Common bits **********)

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

fun rem_or_rand x = let
    val leftover = Int.mod(x, max_val)
in
    if leftover = 0 then
        rand_from_min_to_max 2
    else
        leftover
end

fun rem_all_by_256 t = Tensor.map rem_or_rand t

(********** Vector-specific bits **********)
fun vector iterations size = let
    val vec1 = ITensor.tabulate ([size, 1], fn _ => INumber.zero)
    val vec2 = ITensor.tabulate ([size, 1], fn _ => INumber.one)
    fun runvec 0 _ _ = ()
      | runvec iteration v1 v2 = let
          val next_iter = iteration - 1
          val pluses = ITensor.+(v1, v2)
          val times = v2
      in
          TensorFile.intTensorWriteWithName2 TextIO.stdOut v1 "v1";
          TensorFile.intTensorWriteWithName2 TextIO.stdOut v2 "v2";
          TensorFile.intTensorWriteWithName2 TextIO.stdOut pluses "pluses";
          runvec next_iter pluses times
      end
in
    runvec iterations vec1 vec2
end


(********** Matrix-specific bits **********)
fun matrix iterations size = TextIO.print("Matrix is not implemented yet")

(********** Mixed-specific bits **********)
fun mixed iterations size = TextIO.print("Mixed is not implemented yet")

(********** 'Main' **********)

fun experiment experiment_selection iterations size = let
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
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
in
(* val _ = RunCML.doit ((experiment experiment_selection iterations size), NONE) *)
val _ = experiment experiment_selection iterations size
end
