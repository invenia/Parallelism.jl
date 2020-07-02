module Parallelism

using Base.Threads
using Distributed: ProcessExitedException, pmap
using LinearAlgebra
using Memento

export robust_pmap, tmap, tmap_with_warmup

const MODULE = @__MODULE__
const LOGGER = getlogger(MODULE)

include("robust_pmap.jl")
include("tmap.jl")

end # module
