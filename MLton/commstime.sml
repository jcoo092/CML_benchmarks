fun ID _ _ 0 = ()
fun ID in_ch out_ch count : unit = let
    val next_count = count - 1
    val msg = receive in_ch
in
    send out_ch msg
    ID in_ch out_ch next_count
end

fun prefix N in_ch out_ch count = let
    val next_count = count - 1
in
    send out_ch N
    ID in_ch out_ch count
end

fun successor _ _ 0 = ()
fun successor in_ch out_ch count = let
    val nex_count = count - 1
    val msg = receive in_ch
in
    send out_ch (msg + 1)
         successor in_ch out_ch next_count
end

fun consumer _ 0 = ()
fun consumer in_ch count = let
    val next_count = count - 1
    val msg = receive in_ch
in
    consumer in_ch next_count
end


    fun commstime iterations  = let
        val chans = 5
    val prefix = CML.spawn (prelude 0 iterations)
    val successor = CML.spawn (successor ch1 ch2 iterations)
in
    consumer in_ch iterations
             end


fun experiment (iterations : int) () : unit = let
    (* val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
    val iters_per_thread : int = iterations div num_threads
    val return_ivars = Vector.tabulate (num_threads, (fn _ => SyncVar.iVar())) *)
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
    (* val num_threads = valOf (Int.fromString(List.nth(args, 1))) *)
in
val _ = RunCML.doit ((experiment iterations), NONE)
end
