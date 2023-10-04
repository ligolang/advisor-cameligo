#import "../../src/advisor/main.mligo" "ADVISOR"
#import "../../src/indice/main.mligo" "INDICE"

// ========== DEPLOY CONTRACT HELPER ============
let originate_from_file (type s p) (file_path: string) (storage: s) : (p,s) typed_address =
    let orig = Test.originate_from_file file_path storage 0tez in
    orig.addr

let _test =
  // deploy increment INDICE smart contract 
  let indice_initial_storage = 4 in
  let () = Test.log("deploy increment INDICE smart contract") in
  let inc_indice_address = originate_from_file "../../src/indice/main.mligo" indice_initial_storage in
  // INDICE Increment(1)
  let () = Test.log("call Increment entrypoint of INDICE smart contract") in
  let _increment_gaz = Test.transfer_exn inc_indice_address (Increment 1: INDICE parameter_of) 0mutez in
  let inc_actual_storage = Test.get_storage inc_indice_address in
  let () = Test.log(inc_actual_storage) in
  let () = assert(inc_actual_storage = indice_initial_storage + 1) in

  // deploy decrement INDICE smart contract 
  let () = Test.log("deploy decrement INDICE smart contract") in
  let dec_indice_address = 
    originate_from_file "../../src/indice/main.mligo" indice_initial_storage in
  // INDICE Decrement(2)
  let () = Test.log("call Decrement entrypoint of INDICE smart contract") in
  let _decrement_gaz = Test.transfer_exn dec_indice_address (Decrement 2: INDICE parameter_of) 0mutez in
  let dec_actual_storage = Test.get_storage dec_indice_address in
  let () = Test.log(dec_actual_storage) in
  let () = assert(dec_actual_storage = indice_initial_storage - 2) in

  // deploy ADVISOR contract 
  let () = Test.log("deploy ADVISOR smart contract") in
  let advisor_initial_storage : ADVISOR.storage = {
    indiceAddress=(Test.to_address inc_indice_address); 
    algorithm=(fun(i : int) -> if i < 10 then True else False); 
    result=False;
    metadata=(Big_map.empty: (string, bytes) big_map);
  } in
  let advisor_address = 
    originate_from_file "../../src/advisor/main.mligo" advisor_initial_storage in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract") in
  let _execalgo_gaz = Test.transfer_exn advisor_address (ExecuteAlgorithm (): ADVISOR parameter_of) 0mutez in
  let advisor_modified_storage = Test.get_storage advisor_address in
  let () = Test.log(advisor_modified_storage) in
  let () = assert(advisor_modified_storage.result = True) in

  // ADVISOR call ChangeAlgorithm
  let () = Test.log("call ChangeAlgorithm entrypoint of ADVISOR smart contract") in
  let new_algo : int -> bool = (fun(i : int) -> if i < 3 then True else False) in
  let _changealgo_gaz = Test.transfer_exn advisor_address (ChangeAlgorithm new_algo : ADVISOR parameter_of) 0mutez in
  let _advisor_modified_storage2 = Test.get_storage advisor_address in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract") in
  let _execalgo_gaz_2 = Test.transfer_exn advisor_address (ExecuteAlgorithm () : ADVISOR parameter_of) 0mutez in
  let advisor_modified_storage3 = Test.get_storage advisor_address in
  let () = Test.log(advisor_modified_storage3) in
  assert(advisor_modified_storage3.result = False)

let test_e2e = _test



