open Thread

let writer out_chans num_iterations =
  let writes = List.mapi (fun i ch -> Event.send ch i) out_chans in
  for _i = 1 to num_iterations do
    Event.select writes
  done

let reader in_chans num_iterations =
  let reads = List.map (fun ch -> Event.receive ch) in_chans in
  for _i = 1 to num_iterations do
    let _ = Event.select reads in
    ()
  done

let experiment num_iterations num_chans =
  let chans = List.init num_chans (fun _ -> Event.new_channel()) in
  let r = Thread.create (reader chans) num_iterations in
  let _ = Thread.create (writer chans) num_iterations in
  Thread.join r;;

experiment 5 5;
