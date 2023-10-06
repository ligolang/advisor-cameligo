type indiceStorage = int
type indiceEntrypoints = int
type indiceFullReturn = operation list * indiceStorage

[@entry]
let increment(param : indiceEntrypoints) (store : indiceStorage) : indiceFullReturn = 
    (([]: operation list), store + param)

[@entry]
let decrement(param : indiceEntrypoints) (store : indiceStorage) : indiceFullReturn = 
    (([]: operation list), store - param)