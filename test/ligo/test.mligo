#import "../../contracts/advisor/main.mligo" "ADVISOR"
#import "../../contracts/indice/main.mligo" "INDICE"

// ========== DEPLOY CONTRACT HELPER ============
let originate_from_file (type s p) (file_path: string) (mainName : string) (views: string list) (storage: michelson_program) : address * (p,s) typed_address * p contract =
    let (address_contract, code_contract, _) = Test.originate_from_file file_path mainName views storage 0tez in
    let taddress_contract = (Test.cast_address address_contract : (p, s) typed_address) in
    address_contract, taddress_contract, Test.to_contract taddress_contract

let _test =
  // deploy INDICE smart contract 
  let indice_initial_storage = 4 in
  let () = Test.log("deploy INDICE smart contract") in
  let iis = Test.run (fun (x:INDICE.storage) -> x) indice_initial_storage in
  let (address_indice, indice_taddress, indice_contract) : address * (INDICE.parameter, INDICE.storage) typed_address * INDICE.parameter contract = 
    originate_from_file "contracts/indice/main.mligo" "indiceMain" (["indice_value"] : string list) iis in
  let actual_storage = Test.get_storage_of_address address_indice in

  // INDICE Increment(1)
  let () = Test.log("call Increment entrypoint of INDICE smart contract") in
  let _increment_gaz = Test.transfer_to_contract_exn indice_contract (Increment(1)) 0mutez in
  let inc_actual_storage = Test.get_storage indice_taddress in
  let () = Test.log(inc_actual_storage) in
  let () = assert(inc_actual_storage = indice_initial_storage + 1) in

  // INDICE Decrement(2)
  let () = Test.log("call Decrement entrypoint of INDICE smart contract") in
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
  let ais = Test.run (fun (x:ADVISOR.storage) -> x) advisor_initial_storage in
  let (address_advisor, advisor_taddress, advisor_contract) : address * (ADVISOR.parameter, ADVISOR.storage) typed_address * ADVISOR.parameter contract = 
    originate_from_file "contracts/advisor/main.mligo" "advisorMain" ([] : string list) ais in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract") in
  let _execalgo_gaz = Test.transfer_to_contract_exn advisor_contract (ExecuteAlgorithm(unit)) 0mutez in
  let advisor_modified_storage = Test.get_storage advisor_taddress in
  let () = Test.log(advisor_modified_storage) in
  let () = assert(advisor_modified_storage.result = True) in

  // ADVISOR call ChangeAlgorithm
  let () = Test.log("call ChangeAlgorithm entrypoint of ADVISOR smart contract") in
  let new_algo : int -> bool = (fun(i : int) -> if i < 3 then True else False) in
  let _changealgo_gaz = Test.transfer_to_contract_exn advisor_contract (ChangeAlgorithm(new_algo)) 0mutez in
  let advisor_modified_storage2 = Test.get_storage advisor_taddress in

  // ADVISOR call ExecuteAlgorithm
  let () = Test.log("call ExecuteAlgorithm entrypoint of ADVISOR smart contract") in
  let _execalgo_gaz_2 = Test.transfer_to_contract_exn advisor_contract (ExecuteAlgorithm(unit)) 0mutez in
  let advisor_modified_storage3 = Test.get_storage advisor_taddress in
  let () = Test.log(advisor_modified_storage3) in
  assert(advisor_modified_storage3.result = False)

let test_e2e = _test



