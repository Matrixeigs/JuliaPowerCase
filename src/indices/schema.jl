# ═══════════════════════════════════════════════════════════════════════════════
# Schema Infrastructure — @define_schema macro + ComponentMatrix
#
# This file provides the compile-time symbol→index machinery.
# Individual index files in indices/ define specific schemas.
# ═══════════════════════════════════════════════════════════════════════════════

"""
    AbstractSchema

Supertype for all column-schema singletons.
"""
abstract type AbstractSchema end

"""
    colidx(::Type{S}, ::Val{col}) where {S<:AbstractSchema}

Return the 1-based column index for symbol `col` in schema `S`.
Resolved at **compile time** — zero runtime overhead when `col` is a literal.

# Example
```julia
colidx(BusSchema, Val(:VM))   # → 8  (compiled as a constant)
```
"""
function colidx end

"""
    ncols(::Type{S}) where {S<:AbstractSchema}

Total number of columns defined in schema `S`.
"""
function ncols end

"""
    colnames(::Type{S}) where {S<:AbstractSchema}

Tuple of all column symbols in schema `S`, in order.
"""
function colnames end

# ──────────────────────────────────────────────────────────────────────────────
# @define_schema macro
# ──────────────────────────────────────────────────────────────────────────────

"""
    @define_schema SchemaName COL1 COL2 COL3 ...

Define a compile-time column schema.  Creates:
- `struct SchemaName <: AbstractSchema end`
- `colidx(::Type{SchemaName}, ::Val{:COL1}) = 1`, etc.
- `ncols(::Type{SchemaName}) = N`
- `colnames(::Type{SchemaName}) = (:COL1, :COL2, ...)`

# Example
```julia
@define_schema BusSchema  I  TYPE  PD  QD  GS  BS  AREA  VM  VA  BASE_KV  ZONE  VMAX  VMIN
```
"""
macro define_schema(schema_name, cols...)
    col_syms = Symbol[]
    for c in cols
        if c isa Symbol
            push!(col_syms, c)
        elseif c isa QuoteNode
            push!(col_syms, c.value)
        else
            error("@define_schema: expected Symbol, got $(typeof(c)): $c")
        end
    end

    n = length(col_syms)
    names_tup = Tuple(col_syms)

    # Use GlobalRef to ensure we extend the correct functions
    colidx_fn = GlobalRef(@__MODULE__, :colidx)
    ncols_fn = GlobalRef(@__MODULE__, :ncols)
    colnames_fn = GlobalRef(@__MODULE__, :colnames)

    method_block = Expr(:block)
    for (i, sym) in enumerate(col_syms)
        push!(method_block.args, :(
            @inline $(colidx_fn)(::Type{$(esc(schema_name))}, ::Val{$(QuoteNode(sym))}) = $i
        ))
    end

    return quote
        struct $(esc(schema_name)) <: AbstractSchema end

        $method_block

        @inline $(ncols_fn)(::Type{$(esc(schema_name))})    = $n
        @inline $(colnames_fn)(::Type{$(esc(schema_name))})  = $names_tup
    end
end
