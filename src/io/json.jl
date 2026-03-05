# ═══════════════════════════════════════════════════════════════════════════════
# JSON Import / Export
# ═══════════════════════════════════════════════════════════════════════════════
# Minimal JSON (de)serialisation using Base I/O.
# For full-featured JSON, users should add JSON3.jl.

"""
    save_json(filepath::String, jpc::PowerCaseData)

Export `PowerCaseData` tables as a simple JSON structure.
Each component matrix becomes `{"<name>": [[row1], [row2], ...]}`.
Component names sidecar is written as `{"component_names": {"vsc:1": "name", ...}}`.
"""
function save_json(filepath::String, jpc::PowerCaseData{K, T}) where {K, T}
    open(filepath, "w") do io
        println(io, "{")
        println(io, "  \"name\": $(repr(jpc.name)),")
        println(io, "  \"base_mva\": $(jpc.base_mva),")
        println(io, "  \"base_kv\": $(jpc.base_kv),")

        names = component_names(typeof(jpc))
        written = 0
        for name in names
            mat = component_table(jpc, name)
            nr = nrows(mat)
            nr == 0 && continue
            written += 1
        end
        # Account for component_names if non-empty
        has_cnames = !isempty(jpc.component_names)
        
        # Determine if freq_hz is the last field
        has_content_after = written > 0 || has_cnames
        freq_comma = has_content_after ? "," : ""
        println(io, "  \"freq_hz\": $(jpc.freq_hz)$freq_comma")

        idx = 0
        for name in names
            mat = component_table(jpc, name)
            nr = nrows(mat)
            nr == 0 && continue
            idx += 1
            nc = size(rawdata(mat), 2)
            # Comma if not last item or if component_names follows
            comma = (idx < written || has_cnames) ? "," : ""
            println(io, "  \"$name\": [")
            for r in 1:nr
                row_str = join(["$(rawdata(mat)[r,c])" for c in 1:nc], ", ")
                row_comma = r < nr ? "," : ""
                println(io, "    [$row_str]$row_comma")
            end
            println(io, "  ]$comma")
        end

        # Write component_names sidecar
        if has_cnames
            println(io, "  \"component_names\": {")
            cnames_vec = collect(jpc.component_names)
            for (i, ((ctype, cidx), cname)) in enumerate(cnames_vec)
                comma = i < length(cnames_vec) ? "," : ""
                # Key format: "type:index"
                println(io, "    \"$(ctype):$(cidx)\": $(repr(cname))$comma")
            end
            println(io, "  }")
        end

        println(io, "}")
    end
    return filepath
end
