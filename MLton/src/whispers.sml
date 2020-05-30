fun ring iterations num_threads = let
    fun recv_and_fwd in_ch out_ch = let
    in
        case CML.recv in_ch of
            0 => CML.send(out_ch, 0)
          | msg => (CML.send(out_ch, msg);
                    recv_and_fwd in_ch out_ch)
    end
    fun interpose in_ch out_ch = let
    in case CML.recv in_ch of
           0  => ()
         | msg => ((* MLton.Thread.atomically
                       (fn () => TextIO.print("Message was: " ^ (Int.toString msg) ^ ".\n")); *)
                   CML.send(out_ch, (msg - 1));
                   interpose in_ch out_ch)
    end
    val chans = List.tabulate(num_threads, fn _ => CML.channel ())
    val thds = ListPair.map (
            fn (a, b) => CML.spawn (fn () => recv_and_fwd a b))
                            (chans, (List.tl chans))
    val interpose_thd = CML.spawn (
            fn () => interpose (List.last chans) (List.hd chans))
    val jointhds = List.map CML.joinEvt thds
in
    CML.send((List.hd chans), iterations);
    List.app CML.sync (List.map CML.joinEvt thds);
    CML.sync (CML.joinEvt interpose_thd)
end

fun kn iterations num_threads = let
in
    TextIO.print("kn has not yet been implemented.\n")
end

fun grid iterations num_threads width height = let
in
    TextIO.print("grid has not yet been implemented.\n")
end

fun experiment experiment_selection iterations num_threads width height () = let
in
    case experiment_selection of
        "ring" => ring iterations num_threads
      | "kn" => kn iterations num_threads
      | "grid" => grid iterations num_threads width height
      | _ => raise Fail("Experiment name not recognised.");
    TextIO.print(experiment_selection ^ " of Whispers completed successfully!\n")
end

local
    val default = 50
    val args = CommandLine.arguments()
    val experiment_selection = List.nth(args, 0)
    val iterations = valOf (Int.fromString(List.nth(args, 1)))
    val num_threads = valOf (Int.fromString(List.nth(args, 2)))
    val width = case List.length args of
                    5 => valOf (Int.fromString(List.nth(args, 3)))
                  | 4 => valOf (Int.fromString(List.nth(args, 3)))
                  | _  => default;
    val height = case List.length args of
                     5 => valOf (Int.fromString(List.nth(args, 4)))
                   | _ => default;
in
val _ = RunCML.doit ((experiment experiment_selection iterations num_threads width height), NONE)
end
