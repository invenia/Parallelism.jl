using Parallelism
using Distributed: ProcessExitedException
using Memento
using Memento.TestUtils
using Test

const LOGGER = getlogger()

@testset "Parallelism.jl" begin
   include("robust_pmap.jl")
   include("tmap.jl")
end
