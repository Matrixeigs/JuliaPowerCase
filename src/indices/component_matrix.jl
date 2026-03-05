# ═══════════════════════════════════════════════════════════════════════════════
# ComponentMatrix{S} — Typed Matrix Wrapper with Symbol-Based Column Access
#
# See indices/schema.jl for the @define_schema macro that generates colidx().
# ═══════════════════════════════════════════════════════════════════════════════

"""
    ComponentMatrix{S<:AbstractSchema, T<:Real} <: AbstractMatrix{T}

A typed matrix wrapper where `S` is the column schema.
Supports standard `[i,j]` indexing plus symbol-based `[i, :col]` access.

# Construction
```julia
bus = ComponentMatrix{BusSchema}(zeros(14, ncols(BusSchema)))
bus = ComponentMatrix{BusSchema}(14)          # allocate nrows × ncols
bus = ComponentMatrix{BusSchema}(undef, 14)   # uninitialized
```

# Symbol Indexing
```julia
bus[3, :VM]            # → scalar: voltage magnitude of bus 3
bus[:, :VM]            # → view:   entire VM column
bus[1:5, :VM]          # → view:   VM for buses 1–5
bus[3, :VM] = 1.05     # set voltage magnitude of bus 3
```
"""
struct ComponentMatrix{S<:AbstractSchema, T<:Real} <: AbstractMatrix{T}
    data::Matrix{T}

    function ComponentMatrix{S,T}(data::Matrix{T}) where {S<:AbstractSchema, T<:Real}
        nc = size(data, 2)
        expected = ncols(S)
        nc == expected || nc == 0 ||
            throw(DimensionMismatch(
                "Schema $(nameof(S)) expects $expected columns, got $nc"))
        return new{S,T}(data)
    end
end

# ── Convenience constructors ──────────────────────────────────────────────────

"""Allocate `nrows × ncols(S)` zero matrix."""
ComponentMatrix{S, T}(nrows::Integer) where {S<:AbstractSchema, T<:Real} =
    ComponentMatrix{S,T}(zeros(T, nrows, ncols(S)))

"""Wrap an existing matrix with schema `S`."""
ComponentMatrix{S}(data::Matrix{T}) where {S<:AbstractSchema, T<:Real} =
    ComponentMatrix{S,T}(data)

"""Allocate a zero-initialised `nrows × ncols(S)` matrix (default Float64)."""
ComponentMatrix{S}(nrows::Integer) where {S<:AbstractSchema} =
    ComponentMatrix{S,Float64}(nrows)

"""Allocate an uninitialised `nrows × ncols(S)` matrix."""
ComponentMatrix{S}(::UndefInitializer, nrows::Integer) where {S<:AbstractSchema} =
    ComponentMatrix{S,Float64}(Matrix{Float64}(undef, nrows, ncols(S)))

"""Create an empty (0-row) matrix with the correct column count."""
ComponentMatrix{S}() where {S<:AbstractSchema} =
    ComponentMatrix{S,Float64}(Matrix{Float64}(undef, 0, ncols(S)))


# ── AbstractMatrix interface ──────────────────────────────────────────────────

Base.size(m::ComponentMatrix)          = size(m.data)
Base.size(m::ComponentMatrix, d::Int)  = size(m.data, d)
Base.length(m::ComponentMatrix)        = length(m.data)
Base.eltype(::Type{ComponentMatrix{S,T}}) where {S,T} = T

# Standard integer indexing — explicit signatures to avoid ambiguity with symbol indexing
@inline Base.getindex(m::ComponentMatrix, i::Int)             = m.data[i]
@inline Base.getindex(m::ComponentMatrix, i::Int, j::Int)     = m.data[i, j]
@inline Base.getindex(m::ComponentMatrix, ::Colon, j::Int)    = @view m.data[:, j]
@inline Base.getindex(m::ComponentMatrix, i::Int, ::Colon)    = @view m.data[i, :]
@inline Base.getindex(m::ComponentMatrix, ::Colon, ::Colon)   = m.data
@inline Base.getindex(m::ComponentMatrix, rows::AbstractVector, j::Int) = @view m.data[rows, j]
@inline Base.getindex(m::ComponentMatrix, i::Int, cols::AbstractVector) = @view m.data[i, cols]
@inline Base.getindex(m::ComponentMatrix, rows::AbstractVector, cols::AbstractVector) = @view m.data[rows, cols]

@inline Base.setindex!(m::ComponentMatrix, v, i::Int)           = (m.data[i] = v)
@inline Base.setindex!(m::ComponentMatrix, v, i::Int, j::Int)   = (m.data[i, j] = v)
@inline Base.setindex!(m::ComponentMatrix, v, ::Colon, j::Int)  = (m.data[:, j] .= v)
@inline Base.setindex!(m::ComponentMatrix, v, i::Int, ::Colon)  = (m.data[i, :] .= v)
@inline Base.setindex!(m::ComponentMatrix, v, rows::AbstractVector, j::Int) = (m.data[rows, j] .= v)
@inline Base.setindex!(m::ComponentMatrix, v, i::Int, cols::AbstractVector) = (m.data[i, cols] .= v)
@inline Base.setindex!(m::ComponentMatrix, v, rows::AbstractVector, cols::AbstractVector) = (m.data[rows, cols] .= v)

Base.IndexStyle(::Type{<:ComponentMatrix}) = IndexCartesian()
Base.similar(m::ComponentMatrix{S,T}) where {S,T} =
    ComponentMatrix{S,T}(similar(m.data))
Base.similar(m::ComponentMatrix{S}, ::Type{T}, dims::Dims) where {S,T} =
    similar(m.data, T, dims)
Base.copy(m::ComponentMatrix{S,T}) where {S,T} =
    ComponentMatrix{S,T}(copy(m.data))


# ── Symbol-based column access ───────────────────────────────────────────────

@inline function Base.getindex(m::ComponentMatrix{S}, i::Integer, col::Symbol) where S
    return m.data[i, colidx(S, Val(col))]
end

@inline function Base.getindex(m::ComponentMatrix{S}, ::Colon, col::Symbol) where S
    return @view m.data[:, colidx(S, Val(col))]
end

@inline function Base.getindex(m::ComponentMatrix{S}, rows::AbstractVector, col::Symbol) where S
    return @view m.data[rows, colidx(S, Val(col))]
end

@inline function Base.getindex(m::ComponentMatrix{S}, rows::UnitRange, col::Symbol) where S
    return @view m.data[rows, colidx(S, Val(col))]
end

@inline function Base.setindex!(m::ComponentMatrix{S}, v, i::Integer, col::Symbol) where S
    m.data[i, colidx(S, Val(col))] = v
end

@inline function Base.setindex!(m::ComponentMatrix{S}, v, ::Colon, col::Symbol) where S
    m.data[:, colidx(S, Val(col))] .= v
end

@inline function Base.setindex!(m::ComponentMatrix{S}, v, rows::AbstractVector, col::Symbol) where S
    m.data[rows, colidx(S, Val(col))] .= v
end

@inline function Base.setindex!(m::ComponentMatrix{S}, v, rows::UnitRange, col::Symbol) where S
    m.data[rows, colidx(S, Val(col))] .= v
end


# ── Multi-symbol access ──────────────────────────────────────────────────────

"""
    mat[:, (:PG, :QG)]  → view of columns [PG, QG]
"""
@inline function Base.getindex(m::ComponentMatrix{S}, ::Colon, cols::NTuple{N,Symbol}) where {S, N}
    idxs = ntuple(k -> colidx(S, Val(cols[k])), Val(N))
    return @view m.data[:, collect(idxs)]
end

"""
    mat[i, (:PG, :QG)]  → tuple of values at row i
"""
@inline function Base.getindex(m::ComponentMatrix{S}, row::Integer, cols::NTuple{N,Symbol}) where {S, N}
    return ntuple(k -> m.data[row, colidx(S, Val(cols[k]))], Val(N))
end


# ── Utility functions ─────────────────────────────────────────────────────────

"""Return the underlying `Matrix{T}` for interop with external solvers."""
@inline rawdata(m::ComponentMatrix) = m.data

"""Number of rows (components) in this table."""
@inline nrows(m::ComponentMatrix) = size(m.data, 1)

"""The schema type of this ComponentMatrix."""
schema_type(::ComponentMatrix{S}) where S = S
schema_type(::Type{ComponentMatrix{S,T}}) where {S,T} = S


# ── Pretty printing ──────────────────────────────────────────────────────────

function Base.summary(io::IO, m::ComponentMatrix{S,T}) where {S,T}
    nr, nc = size(m)
    print(io, "$(nr)×$(nc) ComponentMatrix{$(nameof(S)), $T}")
end

function Base.show(io::IO, ::MIME"text/plain", m::ComponentMatrix{S,T}) where {S,T}
    summary(io, m)
    nr = nrows(m)
    if nr == 0
        print(io, " (empty)")
    else
        println(io)
        cols = colnames(S)
        print(io, "  Columns: ")
        join(io, [":$(c)($(i))" for (i,c) in enumerate(cols)], "  ")
        if nr <= 10
            println(io)
            Base.print_matrix(io, m.data)
        else
            println(io, "\n  (showing first 5 and last 5 rows)")
            Base.print_matrix(io, m.data[1:5, :])
            println(io, "\n  ⋮")
            Base.print_matrix(io, m.data[end-4:end, :])
        end
    end
end


# ── Row/Col iteration ─────────────────────────────────────────────────────────

Base.eachrow(m::ComponentMatrix) = eachrow(m.data)
Base.eachcol(m::ComponentMatrix) = eachcol(m.data)
