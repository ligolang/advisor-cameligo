#import "../../contracts/advisor/main.mligo" "ADVISOR"
#import "indice_no_view.mligo" "DUMMY"

let assert_string_failure (res : test_exec_result) (expected : string) : unit =
  let expected = Test.eval expected in
  match res with
  | Fail (Rejected (actual, _)) -> assert (Test.michelson_equal actual expected)
  | Fail (Balance_too_low err) -> failwith "contract failed: balance too low"
  | Fail (Other s) -> failwith s
  | Success n -> failwith "has not failed"

// ========== DEPLOY CONTRACT HELPER ============
let originate_from_file (type s p) (file_path: string) (mainName : string) (views: string list) (storage: michelson_program) : address * (p,s) typed_address * p contract =
    let (address_contract, code_contract, _) = Test.originate_from_file file_path mainName views storage 0tez in
    let taddress_contract = (Test.cast_address address_contract : (p, s) typed_address) in
    address_contract, taddress_contract, Test.to_contract taddress_contract

let test =
  
  // deploy DUMMY smart contract 
  let indice_initial_storage : DUMMY.indiceStorage = 4 in
  let () = Test.log("deploy DUMMY smart contract") in
  // transpile storage in michelson code
  let iis = Test.run (fun (x:DUMMY.indiceStorage) -> x) indice_initial_storage in
  let (address_indice, indice_taddress, indice_contract) : address * (DUMMY.indiceEntrypoints, DUMMY.indiceStorage) typed_address * DUMMY.indiceEntrypoints contract = 
    originate_from_file "test/ligo/indice_no_view.mligo" "indiceMain" ([] : string list) iis in
  let actual_storage = Test.get_storage_of_address address_indice in

  // INDICE Increment(1)
  let () = Test.log("call Increment entrypoint of DUMMY smart contract") in
  let _increment_gaz = Test.transfer_to_contract_exn indice_contract (Increment(1)) 0mutez in
  let inc_actual_storage = Test.get_storage indice_taddress in
  let () = Test.log(inc_actual_storage) in
  let () = assert(inc_actual_storage = indice_initial_storage + 1) in

  // INDICE Decrement(2)
  let () = Test.log("call Decrement entrypoint of DUMMY smart contract") in
  let _decrement_gaz = Test.transfer_to_contract_exn indice_contract (Decrement(2)) 0mutez in
  let dec_actual_storage = Test.get_storage indice_taddress in
  let () = Test.log(dec_actual_storage) in
  let () = assert(dec_actual_storage = inc_actual_storage - 2) in

  // deploy ADVISOR contract 
  let () = Test.log("deploy ADVISOR smart contract") in
  let advisor_initial_storage : ADVISOR.storage = {
    indiceAddress=address_indice;
    algorithm=(fun(i : int) -> if i < 10 then True else False);
    result=False;
    metadata=(Big_map.empty: (string, bytes) big_map);
  } in
  // transpile storage in michelson code
  let ais = Test.run (fun (x:ADVISOR.storage) -> x) advisor_initial_storage in
  let (address_advisor, advisor_taddress, advisor_contract) : address * (ADVISOR.parameter, ADVISOR.storage) typed_address * ADVISOR.parameter contract = 
    originate_from_file "contracts/advisor/main.mligo" "advisorMain" ([] : string list) ais in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract (should fail because DUMMY has no view)") in
  let result : test_exec_result = Test.transfer_to_contract advisor_contract (ExecuteAlgorithm(unit)) 0mutez in
  let () = assert_string_failure result "View indice_value not found" in
  let advisor_modified_storage = Test.get_storage advisor_taddress in
  let () = Test.log(advisor_modified_storage) in
  assert(advisor_modified_storage.result = advisor_initial_storage.result)

