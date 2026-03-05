# ═══════════════════════════════════════════════════════════════════════════════
# Export / Summary Utilities
# ═══════════════════════════════════════════════════════════════════════════════

"""
    export_csv(dirpath::String, jpc::PowerCaseData)

Write each non-empty ComponentMatrix as `<component>.csv` in `dirpath`.
Header row uses schema column names.
"""
function export_csv(dirpath::String, jpc::PowerCaseData{K, T}) where {K, T}
    mkpath(dirpath)
    for name in component_names(typeof(jpc))
        mat = component_table(jpc, name)
        nr = nrows(mat)
        nr == 0 && continue
        S = schema_type(mat)
        cols = colnames(S)
        nc = min(length(cols), size(rawdata(mat), 2))
        filepath = joinpath(dirpath, "$(name).csv")
        open(filepath, "w") do io
            println(io, join(cols[1:nc], ","))
            for r in 1:nr
                println(io, join([rawdata(mat)[r,c] for c in 1:nc], ","))
            end
        end
    end
    return dirpath
end

"""
    print_summary(io::IO, jpc::PowerCaseData)

Print a concise system summary to `io`.
"""
function print_summary(io::IO, jpc::PowerCaseData{K, T}) where {K, T}
    println(io, "═══ JuliaPowerCase Summary ═══")
    println(io, "  System: $(jpc.name)")
    println(io, "  Kind:   $K")
    println(io, "  Base:   $(jpc.base_mva) MVA, $(jpc.freq_hz) Hz")
    for (name, cnt) in summary_table(jpc)
        println(io, "  $(rpad(name, 12)): $cnt")
    end
end

print_summary(jpc::PowerCaseData) = print_summary(stdout, jpc)
