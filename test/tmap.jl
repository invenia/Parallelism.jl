@testset "threading" begin
    @testset "$fancy_map" for fancy_map in (tmap, tmap_with_warmup)
        @testset "basesize=$basesize" for basesize in (1, 2, 3, 100)
            @test fancy_map(x->2x, [1, 2, 3, 4]; basesize=basesize) == [2, 4, 6, 8]

            @test isequal(
                fancy_map(+, [1, 2, 3, 4, 5], [10, 20, 30, 40, 50]; basesize=basesize),
                [11, 22, 33, 44, 55]
            )
        end

        # Make sure that do blocks like in the pipeline work
        # got to make sure brackets are in right place
        @test  [11, 22, 33] == fancy_map([1, 2, 3], [10, 20, 30]) do x, y
            x+y
        end

        # Test that incorrectly brackets do blocks do not
        # Note: for tmap it is a TaskFailedException wrapping a MethodError
        # for tmap_with_warmup it is a MethodError
        # We are actually fine with either from either so we just test the Union
        ExpectedException = Union{TaskFailedException, MethodError}
        @test_throws ExpectedException fancy_map([1, 2, 3], [10, 20, 30]) do (x, y)
            x+y
        end
    end
end
