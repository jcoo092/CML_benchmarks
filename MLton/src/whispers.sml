(********** Ring-specific bits **********)
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

(********** Kn-specific bits **********)

fun dotalk 0 [] _ _ = ()
  | dotalk 0 sendEvts recvEvt self = let
      val _ = CML.sync (List.hd sendEvts)
  in
      dotalk 0 (List.tl sendEvts) recvEvt self
  end
  | dotalk count [] recvEvt self = let
      val _ = CML.sync recvEvt
  in
      dotalk (count - 1) [] recvEvt self
  end
  | dotalk count sendEvts recvEvt self = let
      val msg = CML.select [recvEvt, (List.hd sendEvts)]
  in
      if msg = self then
          dotalk count (List.tl sendEvts) recvEvt self
      else
          dotalk (count - 1) sendEvts recvEvt self
  end

fun communicate iterations count sendEvts i recvCh = let
    (* The below wrap is used for debugging purposes, and isn't normally needed *)
    (* val recv_evt = CML.wrap (CML.recvEvt recvCh,
                             fn v => (MLton.Thread.atomically
                                          (fn () => TextIO.print ("Thread " ^ (Int.toString i) ^
                                                                  " received from thread " ^ (Int.toString v) ^ ".\n")); v)) *)
    val recv_evt = CML.recvEvt recvCh
    fun runtalk 0 = ()
      | runtalk iteration = let
          val _ = dotalk count sendEvts recv_evt i
      in
          runtalk (iteration - 1)
      end
in
    runtalk iterations
end

fun kn iterations num_threads = let
    val count = num_threads - 1
    val chans = List.tabulate (num_threads, fn _ => CML.channel ())
    val part_send_evts = List.map (fn c => fn v => CML.wrap (CML.sendEvt (c, v), fn _ => v)) chans
    val thds = ListPair.mapEq
                   (fn (i, c) => let val sends = (List.take (part_send_evts, i)) @ (List.drop (part_send_evts, (i + 1)))
                                     val sendEvts = List.map (fn s => s i) sends
                                 in
                                     CML.spawn(fn () => communicate iterations count sendEvts i c)
                                 end) (List.tabulate(num_threads, fn i => i), chans)
in
    List.app (fn t => CML.sync (CML.joinEvt t)) thds
end

(********** Grid-specific bits **********)

fun grid iterations num_threads width height = let
in
    TextIO.print("grid has not yet been implemented.\n")
end

(********** General-purpose bits **********)

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
