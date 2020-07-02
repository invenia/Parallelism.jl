"""
    _tmap(f, xs...)

An internal helper for `tmap` that handles the `basesize == 1` case.
"""
function _tmap(f, xss...)
    # Set the number of threads that BLAS uses to 1 here in case it's using up too many
    nthreads() > 1 && LinearAlgebra.BLAS.set_num_threads(1)
    futures = map(xss...) do x...
        Threads.@spawn f(x...)
    end
    results = map(fetch, futures)

     # Bump up the BLAS threads once we're done
    nthreads() > 1 && LinearAlgebra.BLAS.set_num_threads(typemax(Int32))

    return results
end

"""
    _tmap_with_partition(f, xss...; basesize)

An internal helper for `tmap` that handles the `basesize > 1` case.
Works for `basesize == 1`, but less efficent; since it breaks things up into single
item slices then stiches them back together again.
"""
function _tmap_with_partition(f, xss...; basesize)
    partitioned_xss = Iterators.partition.(xss, basesize)
    partioned_ys = _tmap(partitioned_xss...) do xss...
        map(f, xss...)
    end
    return reduce(vcat, partioned_ys)
end

"""
    tmap(f, xs...; basesize=1)

Multithreaded version of `map`.
`basesize` controls the minimum number of items from `xs` to process per `@spawn`ed task.

!!! tip
    `basesize` should be set high enough that proccessing that
    many items takes about ~1ms. This is to counter the ~50μs overhead
    it takes to dispatch work to a thread. If the function takes >1ms per
    call, then `basesize=1` is recommended.
"""
function tmap(f, xss...; basesize=1)
    if basesize == 1
        _tmap(f, xss...)
    else
        _tmap_with_partition(f, xss...; basesize=basesize)
    end
end


"""
    tmap_with_warmup(f, xs...; basesize=1)

Similar to [`tmap`](@ref), but runs the first call single threaded, before multithreading
the remainnder.
This is useful for dealing with things that benifit from something happening on first run.
Which might be related to caching values, or some compilation troubles.

`basesize` controls the minimum number of items from `xs` to process per `@spawn`ed task.

See [`tmap`](@ref) for more details
"""
function tmap_with_warmup(f, xss...; basesize=1)
    xs = first.(xss)
    xs_tails = Iterators.rest.(xss, 2)

    y = f(xs...)
    ys_tail = tmap(f, xs_tails...; basesize=basesize)
    ys = pushfirst!(ys_tail, y)
    return ys
end
