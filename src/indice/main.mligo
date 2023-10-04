type parameter = int
type storage = int
type return = operation list * storage

[@entry]
let increment (param : parameter) (store : storage) : return = 
    (([]: operation list), store + param)

[@entry]
let decrement (param : parameter) (store : storage) : return = 
    (([]: operation list), store - param)

[@view] let indice_value(_ : unit) (store : storage) : int = store