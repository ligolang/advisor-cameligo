#import "errors.mligo" "Errors"
#import "parameter.mligo" "Parameter"
#import "storage.mligo" "Storage"
#import "algo.mligo" "Algo"

type storage = Storage.Types.t
type parameter = Algo.Types.t
type return = operation list * storage

[@entry]
let changeAlgorithm (p : parameter) (s : storage) : return =
    [], Storage.Utils.change (p, s)

[@entry]
let executeAlgorithm (_ : unit) (s : storage) : return =
    [], Storage.Utils.executeAlgorithm (s)