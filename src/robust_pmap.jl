"""
    robust_pmap(f::Function, xs::Any, num_retries::Int=3)

A pmap function with retries for common network errors.
"""
function robust_pmap(f::Function, args...; num_retries::Int=3)

    # This function returns true if we should retry and fails if we should error out.
    function retry_check(delay_state, err)
        # Below each condition to retry is listed along with an explanation about why
        # retrying should/might work.
        should_retry = (
            # Worker death is normally stocastic, if not then doesn't matter how many
            # retries as it will rapidly kill all workers
            err isa ProcessExitedException ||
            # If we are in the middle of fetching data and the process is killed we could
            # get an ArgumentError saying that the stream was closed or unusable.
            # So same as above.
            err isa ArgumentError && occursin("stream is closed or unusable", err.msg) ||
            # In general IO errors can be transient and related to network blips
            err isa Base.IOError
        )
        if should_retry
            info(LOGGER, "Retrying computation that failed due to a $(typeof(err)): $err")
        else
            info(LOGGER, "Non-retryable $(typeof(err)) occurred: $err")
        end
        return should_retry
    end

    return pmap(f, CachingPool(workers()), args...;
        retry_check=retry_check,
        retry_delays=ExponentialBackOff(n=num_retries)
    )
end
