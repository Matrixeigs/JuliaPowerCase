# ═══════════════════════════════════════════════════════════════════════════════
# Abstract Type Hierarchy
# ═══════════════════════════════════════════════════════════════════════════════

# ── System Kind — Phantom Type Tags ──────────────────────────────────────────

"""
    SystemKind

Abstract supertype for AC/DC phantom tags.
"""
abstract type SystemKind end

"""
    AC <: SystemKind

Tag for alternating-current components and subsystems.
"""
struct AC <: SystemKind end

"""
    DC <: SystemKind

Tag for direct-current components and subsystems.
"""
struct DC <: SystemKind end

# ── Component Hierarchy ──────────────────────────────────────────────────────

"""Supertype for all power system component structs."""
abstract type AbstractComponent end

"""AC/DC bus."""
abstract type AbstractBus <: AbstractComponent end

"""Line, cable, transformer branch."""
abstract type AbstractBranch <: AbstractComponent end

"""Synchronous or static generator."""
abstract type AbstractGenerator <: AbstractComponent end

"""Constant or flexible load."""
abstract type AbstractLoad <: AbstractComponent end

"""Battery, flywheel, or other storage device."""
abstract type AbstractStorage <: AbstractComponent end

"""AC/DC converter, VSC, LCC."""
abstract type AbstractConverter <: AbstractComponent end

"""Circuit breaker, switch, fuse."""
abstract type AbstractSwitch <: AbstractComponent end

# ── Enums ─────────────────────────────────────────────────────────────────────

"""Bus type codes stored in the TYPE column."""
@enum BusType::Int32 begin
    PQ_BUS       = 1
    PV_BUS       = 2
    REF_BUS      = 3
    ISOLATED_BUS = 4
end

"""Generator cost model selector."""
@enum GenModel::Int32 begin
    NONE_MODEL = 0
    PIECEWISE_LINEAR = 1
    POLYNOMIAL_MODEL = 2
end

# ── Custom Exceptions ─────────────────────────────────────────────────────────

"""
    PowerCaseError <: Exception

Base exception type for JuliaPowerCase errors.
"""
abstract type PowerCaseError <: Exception end

"""
    ValidationError <: PowerCaseError

Exception for validation failures in power system data.
"""
struct PowerCaseValidationError <: PowerCaseError
    message::String
    component::Symbol
    details::Vector{String}
end

PowerCaseValidationError(msg::String) = PowerCaseValidationError(msg, :unknown, String[])
PowerCaseValidationError(msg::String, comp::Symbol) = PowerCaseValidationError(msg, comp, String[])

function Base.showerror(io::IO, e::PowerCaseValidationError)
    print(io, "PowerCaseValidationError: ", e.message)
    if e.component != :unknown
        print(io, " (component: ", e.component, ")")
    end
    if !isempty(e.details)
        print(io, "\n  Details:")
        for d in e.details
            print(io, "\n    - ", d)
        end
    end
end

"""
    ForeignKeyError <: PowerCaseError

Exception for foreign key reference violations.
"""
struct ForeignKeyError <: PowerCaseError
    message::String
    source_table::Symbol
    target_table::Symbol
    invalid_refs::Vector{Int}
end

function Base.showerror(io::IO, e::ForeignKeyError)
    print(io, "ForeignKeyError: ", e.message)
    print(io, " (", e.source_table, " -> ", e.target_table, ")")
    if !isempty(e.invalid_refs)
        print(io, "\n  Invalid references: ", e.invalid_refs)
    end
end

"""
    SchemaError <: PowerCaseError

Exception for schema-related errors (invalid columns, type mismatches).
"""
struct SchemaError <: PowerCaseError
    message::String
    schema::Symbol
end

function Base.showerror(io::IO, e::SchemaError)
    print(io, "SchemaError[", e.schema, "]: ", e.message)
end
