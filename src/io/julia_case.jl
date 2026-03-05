# ═══════════════════════════════════════════════════════════════════════════════
# Julia Case File Format (native .jl)
# ═══════════════════════════════════════════════════════════════════════════════

"""
    save_julia_case(filepath::String, jpc::PowerCaseData)

Write a `PowerCaseData` as a self-contained Julia source file that,
when `include`d, returns the case.
"""
function save_julia_case(filepath::String, jpc::PowerCaseData{K, T}) where {K, T}
    open(filepath, "w") do io
        println(io, "# JuliaPowerCase — auto-generated case file")
        println(io, "# $(Dates.now())")
        println(io, "using JuliaPowerCase")
        println(io)
        println(io, "function build_case()")
        println(io, "    jpc = PowerCaseData{$K, $T}()")
        println(io, "    jpc.name     = $(repr(jpc.name))")
        println(io, "    jpc.base_mva = $T($(jpc.base_mva))")
        println(io, "    jpc.base_kv  = $T($(jpc.base_kv))")
        println(io, "    jpc.freq_hz  = $T($(jpc.freq_hz))")
        println(io)

        # Write each non-empty table
        for name in component_names(typeof(jpc))
            mat = component_table(jpc, name)
            nr = nrows(mat)
            nr == 0 && continue
            nc = size(rawdata(mat), 2)
            println(io, "    jpc.$name = ComponentMatrix{$(schema_type(mat)), $T}(")
            println(io, "        $T[")
            for r in 1:nr
                vals = join(["$(rawdata(mat)[r,c])" for c in 1:nc], " ")
                println(io, "            $vals;")
            end
            println(io, "        ])")
            println(io)
        end

        # Write component_names sidecar if non-empty
        if !isempty(jpc.component_names)
            println(io, "    # Component names sidecar (for string name preservation)")
            for ((ctype, idx), name) in jpc.component_names
                println(io, "    jpc.component_names[($(repr(ctype)), $idx)] = $(repr(name))")
            end
            println(io)
        end

        println(io, "    return jpc")
        println(io, "end")
        println(io)
        println(io, "build_case()")
    end
    return filepath
end

"""
    load_julia_case(filepath::String) -> PowerCaseData

Load a case from a Julia case file written by `save_julia_case`.
"""
function load_julia_case(filepath::String)
    !isfile(filepath) && throw(ArgumentError("File not found: $filepath"))
    return include(filepath)
end
