using Documenter, Parallelism

makedocs(;
    modules=[Parallelism],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/invenia/Parallelism.jl/blob/{commit}{path}#L{line}",
    sitename="Parallelism.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
)

deploydocs(;
    repo="github.com/invenia/Parallelism.jl",
)
