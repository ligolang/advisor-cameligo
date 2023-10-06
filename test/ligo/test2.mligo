#import "../../src/advisor/main.mligo" "ADVISOR"
#import "indice_no_view.mligo" "DUMMY"

let assert_string_failure (res : test_exec_result) (expected : string) : unit =
  let expected = Test.eval expected in
  match res with
  | Fail (Rejected (actual, _)) -> assert (Test.michelson_equal actual expected)
  | Fail (Balance_too_low _) -> failwith "contract failed: balance too low"
  | Fail (Other s) -> failwith s
  | Success _ -> failwith "has not failed"

// ========== DEPLOY CONTRACT HELPER ============
let originate_from_file (type s p) (file_path: string) (storage: s) : (p,s) typed_address =
    let res = Test.originate_from_file file_path storage 0tez in
    res.addr

let test =
  let indice_initial_storage : DUMMY.indiceStorage = 4 in
  
  // deploy increment DUMMY smart contract 
  let () = Test.log("deploy increment DUMMY smart contract") in
  let inc_indice_address = originate_from_file "./indice_no_view.mligo" indice_initial_storage in

  // INDICE Increment(1)
  let () = Test.log("call Increment entrypoint of DUMMY smart contract") in
  let _increment_gaz = Test.transfer_exn inc_indice_address (Increment 1 : DUMMY parameter_of) 0mutez in
  let inc_actual_storage = Test.get_storage inc_indice_address in
  let () = Test.log(inc_actual_storage) in
  let () = assert(inc_actual_storage = indice_initial_storage + 1) in

  // deploy decrement DUMMY smart contract 
  let () = Test.log("deploy decrement DUMMY smart contract") in
  let dec_indice_address = originate_from_file "./indice_no_view.mligo" indice_initial_storage in

  // INDICE Decrement(2)
  let () = Test.log("call Decrement entrypoint of DUMMY smart contract") in
  let _decrement_gaz = Test.transfer_exn dec_indice_address (Decrement 2 : DUMMY parameter_of) 0mutez in
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
  // transpile storage in michelson code
  let advisor_address = 
    originate_from_file "../../src/advisor/main.mligo" advisor_initial_storage in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract (should fail because DUMMY has no view)") in
  let result : test_exec_result = Test.transfer advisor_address (ExecuteAlgorithm (): ADVISOR parameter_of) 0mutez in
  let () = assert_string_failure result "View indice_value not found" in
  let advisor_modified_storage = Test.get_storage advisor_address in
  let () = Test.log(advisor_modified_storage) in
  assert(advisor_modified_storage.result = advisor_initial_storage.result)

