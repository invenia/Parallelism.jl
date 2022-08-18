@testset "robust_pmap" begin
    input = [1, 2, 3, 4]
    expected = [true, false, true, false]
    @test robust_pmap(isodd, input) == expected

    function make_throw_isodd(err)
        i = 0
        function throw_isodd(x)
            if i < 2  # Throws error twice before succeeding
                i += 1
                throw(err)
            end
            return isodd(x)
        end
        return throw_isodd
    end

    # Check other errors don't retry
    throw_isodd = make_throw_isodd(ErrorException("Error"))
    if VERSION < v"1.8-"
        @test_throws ErrorException robust_pmap(throw_isodd, input)
    else
        @test_throws "Error" robust_pmap(throw_isodd, input)
    end

    # Check ProcessExitedException is retried
    throw_isodd = make_throw_isodd(ProcessExitedException())
    @test robust_pmap(throw_isodd, input) == expected
    # Check retries are logged
    throw_isodd = make_throw_isodd(ProcessExitedException())
    @test_log LOGGER "info" ("Retrying", "ProcessExitedException") robust_pmap(
        throw_isodd, input
    )
    # Check with lower number of retrys
    throw_isodd = make_throw_isodd(ProcessExitedException())
    if VERSION < v"1.8-"
        @test_throws ProcessExitedException robust_pmap(throw_isodd, input, num_retries=1)

    else
        @test_throws "ProcessExitedException" robust_pmap(throw_isodd, input, num_retries=1)
    end
    # ArgumentErrors with this message should be retried
    throw_isodd = make_throw_isodd(ArgumentError("stream is closed or unusable"))
    @test robust_pmap(throw_isodd, input) == expected
    # Check retries are logged
    throw_isodd = make_throw_isodd(ArgumentError("stream is closed or unusable"))
    @test_log LOGGER "info" ("Retrying", "ArgumentError") robust_pmap(throw_isodd, input)
    # Check with lower number of retrys
    throw_isodd = make_throw_isodd(ArgumentError("stream is closed or unusable"))
    if VERSION < v"1.8-"
        @test_throws ArgumentError robust_pmap(throw_isodd, input, num_retries=1)
    else
        @test_throws "stream is closed or unusable" robust_pmap(
            throw_isodd, input, num_retries=1
        )
    end

    # Other ArgumentErrors should not be retried
    throw_isodd = make_throw_isodd(ArgumentError("stream is open but other stuff is wrong"))
    if VERSION < v"1.8-"
        @test_throws ArgumentError robust_pmap(throw_isodd, input)
    else
        @test_throws "stream is open but other stuff is wrong" robust_pmap(
            throw_isodd, input
        )
    end
    # No retries should mean no log of retries
    throw_isodd = make_throw_isodd(ArgumentError("stream is open but other stuff is wrong"))
    @test_nolog LOGGER "info" "Retrying" try
        robust_pmap(throw_isodd, input)
    catch
    end

    # Check IOError is retried
    throw_isodd = make_throw_isodd(Base.IOError("msg", 1))
    @test robust_pmap(throw_isodd, input) == expected
    # Check retries are logged
    throw_isodd = make_throw_isodd(Base.IOError("msg", 1))
    @test_log LOGGER "info" ("Retrying", "IOError") robust_pmap(throw_isodd, input)
    # Check with lower number of retrys
    throw_isodd = make_throw_isodd(Base.IOError("msg", 1))
    if VERSION < v"1.8-"
        @test_throws Base.IOError robust_pmap(throw_isodd, input, num_retries=1)
    else
        @test_throws "msg" robust_pmap(throw_isodd, input, num_retries=1)
    end
end
