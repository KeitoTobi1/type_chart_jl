module Charts

export build_chart_gen1, build_chart_gen6, build_chart_gen3, TYPES_GEN1, TYPES_GEN6, TYPES_GEN3, save_chart_json

using JSON

const TYPES_GEN1 = [
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic", "bug",
    "rock", "ghost", "dragon"
]

const TYPES_GEN6 = [
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic", "bug",
    "rock", "ghost", "dragon", "dark", "steel", "fairy"
]

const TYPES_GEN3 = [
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic", "bug",
    "rock", "ghost", "dragon", "dark", "steel"
]

"""
    build_chart_gen1()

初代（Gen 1: 赤・緑・青・ピカチュウ）のタイプ相性表を構築します。
特徴:
- 15タイプ（あく・はがね・フェアリーなし）
- 初代のゴースト設計ミス: ゴースト攻撃 -> エスパー防御 = 0.0（無効）
- 初代固有相性:
  - むし攻撃 -> どく防御 = 2.0（抜群）
  - どく攻撃 -> むし防御 = 2.0（抜群）
  - こおり攻撃 -> ほのお防御 = 1.0（等倍）
"""
function build_chart_gen1()::Dict{String, Dict{String, Float64}}
    types = TYPES_GEN1
    chart = Dict{String, Dict{String, Float64}}()
    for atk in types
        chart[atk] = Dict{String, Float64}()
        for def in types
            chart[atk][def] = 1.0
        end
    end

    # normal
    chart["normal"]["rock"] = 0.5
    chart["normal"]["ghost"] = 0.0

    # fire
    chart["fire"]["fire"] = 0.5
    chart["fire"]["water"] = 0.5
    chart["fire"]["grass"] = 2.0
    chart["fire"]["ice"] = 2.0
    chart["fire"]["bug"] = 2.0
    chart["fire"]["rock"] = 0.5
    chart["fire"]["dragon"] = 0.5

    # water
    chart["water"]["fire"] = 2.0
    chart["water"]["water"] = 0.5
    chart["water"]["grass"] = 0.5
    chart["water"]["ground"] = 2.0
    chart["water"]["rock"] = 2.0
    chart["water"]["dragon"] = 0.5

    # electric
    chart["electric"]["water"] = 2.0
    chart["electric"]["electric"] = 0.5
    chart["electric"]["grass"] = 0.5
    chart["electric"]["ground"] = 0.0
    chart["electric"]["flying"] = 2.0
    chart["electric"]["dragon"] = 0.5

    # grass
    chart["grass"]["fire"] = 0.5
    chart["grass"]["water"] = 2.0
    chart["grass"]["grass"] = 0.5
    chart["grass"]["poison"] = 0.5
    chart["grass"]["ground"] = 2.0
    chart["grass"]["flying"] = 0.5
    chart["grass"]["bug"] = 0.5
    chart["grass"]["rock"] = 2.0
    chart["grass"]["dragon"] = 0.5

    # ice (Gen 1 では炎に等倍)
    chart["ice"]["water"] = 0.5
    chart["ice"]["grass"] = 2.0
    chart["ice"]["ice"] = 0.5
    chart["ice"]["ground"] = 2.0
    chart["ice"]["flying"] = 2.0
    chart["ice"]["dragon"] = 2.0

    # fighting
    chart["fighting"]["normal"] = 2.0
    chart["fighting"]["ice"] = 2.0
    chart["fighting"]["poison"] = 0.5
    chart["fighting"]["flying"] = 0.5
    chart["fighting"]["psychic"] = 0.5
    chart["fighting"]["bug"] = 0.5
    chart["fighting"]["rock"] = 2.0
    chart["fighting"]["ghost"] = 0.0

    # poison (Gen 1 では虫に抜群)
    chart["poison"]["grass"] = 2.0
    chart["poison"]["poison"] = 0.5
    chart["poison"]["ground"] = 0.5
    chart["poison"]["bug"] = 2.0
    chart["poison"]["rock"] = 0.5
    chart["poison"]["ghost"] = 0.5

    # ground
    chart["ground"]["fire"] = 2.0
    chart["ground"]["electric"] = 2.0
    chart["ground"]["grass"] = 0.5
    chart["ground"]["poison"] = 2.0
    chart["ground"]["flying"] = 0.0
    chart["ground"]["bug"] = 0.5
    chart["ground"]["rock"] = 2.0

    # flying
    chart["flying"]["electric"] = 0.5
    chart["flying"]["grass"] = 2.0
    chart["flying"]["fighting"] = 2.0
    chart["flying"]["bug"] = 2.0
    chart["flying"]["rock"] = 0.5

    # psychic (Gen 1 ではゴーストに等倍)
    chart["psychic"]["fighting"] = 2.0
    chart["psychic"]["poison"] = 2.0
    chart["psychic"]["psychic"] = 0.5

    # bug (Gen 1 では毒に抜群)
    chart["bug"]["fire"] = 0.5
    chart["bug"]["grass"] = 2.0
    chart["bug"]["fighting"] = 0.5
    chart["bug"]["poison"] = 2.0
    chart["bug"]["flying"] = 0.5
    chart["bug"]["psychic"] = 2.0
    chart["bug"]["ghost"] = 0.5

    # rock
    chart["rock"]["fire"] = 2.0
    chart["rock"]["ice"] = 2.0
    chart["rock"]["fighting"] = 0.5
    chart["rock"]["ground"] = 0.5
    chart["rock"]["flying"] = 2.0
    chart["rock"]["bug"] = 2.0

    # ghost (初代の設計ミス: エスパーに無効)
    chart["ghost"]["normal"] = 0.0
    chart["ghost"]["psychic"] = 0.0
    chart["ghost"]["ghost"] = 2.0

    # dragon
    chart["dragon"]["dragon"] = 2.0

    return chart
end

"""
    build_chart_gen6()

フェアリータイプ登場後（Gen 6+ / 現代）のタイプ相性表を構築します。
特徴:
- 18タイプ（フェアリー追加）
- はがねの耐性変更: ゴースト・あく攻撃が等倍 (1.0)
- フェアリータイプ:
  - 攻撃時: かくとう・ドラゴン・あくに2.0、ほのお・どく・はがねに0.5
  - 防御時: どく・はがねが2.0、かくとう・むし・あくが0.5、ドラゴンが無効(0.0)
"""
function build_chart_gen6()::Dict{String, Dict{String, Float64}}
    types = TYPES_GEN6
    chart = Dict{String, Dict{String, Float64}}()
    for atk in types
        chart[atk] = Dict{String, Float64}()
        for def in types
            chart[atk][def] = 1.0
        end
    end

    # normal
    chart["normal"]["rock"] = 0.5
    chart["normal"]["ghost"] = 0.0
    chart["normal"]["steel"] = 0.5

    # fire
    chart["fire"]["fire"] = 0.5
    chart["fire"]["water"] = 0.5
    chart["fire"]["grass"] = 2.0
    chart["fire"]["ice"] = 2.0
    chart["fire"]["bug"] = 2.0
    chart["fire"]["rock"] = 0.5
    chart["fire"]["dragon"] = 0.5
    chart["fire"]["steel"] = 2.0

    # water
    chart["water"]["fire"] = 2.0
    chart["water"]["water"] = 0.5
    chart["water"]["grass"] = 0.5
    chart["water"]["ground"] = 2.0
    chart["water"]["rock"] = 2.0
    chart["water"]["dragon"] = 0.5

    # electric
    chart["electric"]["water"] = 2.0
    chart["electric"]["electric"] = 0.5
    chart["electric"]["grass"] = 0.5
    chart["electric"]["ground"] = 0.0
    chart["electric"]["flying"] = 2.0
    chart["electric"]["dragon"] = 0.5

    # grass
    chart["grass"]["fire"] = 0.5
    chart["grass"]["water"] = 2.0
    chart["grass"]["grass"] = 0.5
    chart["grass"]["poison"] = 0.5
    chart["grass"]["ground"] = 2.0
    chart["grass"]["flying"] = 0.5
    chart["grass"]["bug"] = 0.5
    chart["grass"]["rock"] = 2.0
    chart["grass"]["dragon"] = 0.5
    chart["grass"]["steel"] = 0.5

    # ice
    chart["ice"]["fire"] = 0.5
    chart["ice"]["water"] = 0.5
    chart["ice"]["grass"] = 2.0
    chart["ice"]["ice"] = 0.5
    chart["ice"]["ground"] = 2.0
    chart["ice"]["flying"] = 2.0
    chart["ice"]["dragon"] = 2.0
    chart["ice"]["steel"] = 0.5

    # fighting
    chart["fighting"]["normal"] = 2.0
    chart["fighting"]["ice"] = 2.0
    chart["fighting"]["poison"] = 0.5
    chart["fighting"]["flying"] = 0.5
    chart["fighting"]["psychic"] = 0.5
    chart["fighting"]["bug"] = 0.5
    chart["fighting"]["rock"] = 2.0
    chart["fighting"]["ghost"] = 0.0
    chart["fighting"]["dark"] = 2.0
    chart["fighting"]["steel"] = 2.0
    chart["fighting"]["fairy"] = 0.5

    # poison
    chart["poison"]["grass"] = 2.0
    chart["poison"]["poison"] = 0.5
    chart["poison"]["ground"] = 0.5
    chart["poison"]["rock"] = 0.5
    chart["poison"]["ghost"] = 0.5
    chart["poison"]["steel"] = 0.0
    chart["poison"]["fairy"] = 2.0

    # ground
    chart["ground"]["fire"] = 2.0
    chart["ground"]["electric"] = 2.0
    chart["ground"]["grass"] = 0.5
    chart["ground"]["poison"] = 2.0
    chart["ground"]["flying"] = 0.0
    chart["ground"]["bug"] = 0.5
    chart["ground"]["rock"] = 2.0
    chart["ground"]["steel"] = 2.0

    # flying
    chart["flying"]["electric"] = 0.5
    chart["flying"]["grass"] = 2.0
    chart["flying"]["fighting"] = 2.0
    chart["flying"]["bug"] = 2.0
    chart["flying"]["rock"] = 0.5
    chart["flying"]["steel"] = 0.5

    # psychic
    chart["psychic"]["fighting"] = 2.0
    chart["psychic"]["poison"] = 2.0
    chart["psychic"]["psychic"] = 0.5
    chart["psychic"]["dark"] = 0.0
    chart["psychic"]["steel"] = 0.5

    # bug
    chart["bug"]["fire"] = 0.5
    chart["bug"]["grass"] = 2.0
    chart["bug"]["fighting"] = 0.5
    chart["bug"]["poison"] = 0.5
    chart["bug"]["flying"] = 0.5
    chart["bug"]["psychic"] = 2.0
    chart["bug"]["ghost"] = 0.5
    chart["bug"]["steel"] = 0.5
    chart["bug"]["fairy"] = 0.5

    # rock
    chart["rock"]["fire"] = 2.0
    chart["rock"]["ice"] = 2.0
    chart["rock"]["fighting"] = 0.5
    chart["rock"]["ground"] = 0.5
    chart["rock"]["flying"] = 2.0
    chart["rock"]["bug"] = 2.0
    chart["rock"]["steel"] = 0.5

    # ghost (Gen 6+: 鋼に等倍)
    chart["ghost"]["normal"] = 0.0
    chart["ghost"]["psychic"] = 2.0
    chart["ghost"]["ghost"] = 2.0
    chart["ghost"]["dark"] = 0.5
    # chart["ghost"]["steel"] = 1.0 (デフォルトのまま)

    # dragon
    chart["dragon"]["dragon"] = 2.0
    chart["dragon"]["steel"] = 0.5
    chart["dragon"]["fairy"] = 0.0

    # dark (Gen 6+: 鋼に等倍)
    chart["dark"]["fighting"] = 0.5
    chart["dark"]["psychic"] = 2.0
    chart["dark"]["ghost"] = 2.0
    chart["dark"]["dark"] = 0.5
    chart["dark"]["fairy"] = 0.5
    # chart["dark"]["steel"] = 1.0 (デフォルトのまま)

    # steel
    chart["steel"]["fire"] = 0.5
    chart["steel"]["water"] = 0.5
    chart["steel"]["electric"] = 0.5
    chart["steel"]["ice"] = 2.0
    chart["steel"]["rock"] = 2.0
    chart["steel"]["steel"] = 0.5
    chart["steel"]["fairy"] = 2.0

    # fairy
    chart["fairy"]["fire"] = 0.5
    chart["fairy"]["fighting"] = 2.0
    chart["fairy"]["poison"] = 0.5
    chart["fairy"]["dragon"] = 2.0
    chart["fairy"]["dark"] = 2.0
    chart["fairy"]["steel"] = 0.5

    return chart
end

"""
    build_chart_gen3()

第3世代（Gen 3: ルビー・サファイア）のタイプ相性表を構築します。
（元リポジトリのタイプ相性との互換性のために提供）
"""
function build_chart_gen3()::Dict{String, Dict{String, Float64}}
    types = TYPES_GEN3
    chart = Dict{String, Dict{String, Float64}}()
    for atk in types
        chart[atk] = Dict{String, Float64}()
        for def in types
            chart[atk][def] = 1.0
        end
    end

    # normal
    chart["normal"]["rock"] = 0.5
    chart["normal"]["ghost"] = 0.0
    chart["normal"]["steel"] = 0.5

    # fire
    chart["fire"]["fire"] = 0.5
    chart["fire"]["water"] = 0.5
    chart["fire"]["grass"] = 2.0
    chart["fire"]["ice"] = 2.0
    chart["fire"]["bug"] = 2.0
    chart["fire"]["rock"] = 0.5
    chart["fire"]["dragon"] = 0.5
    chart["fire"]["steel"] = 2.0

    # water
    chart["water"]["fire"] = 2.0
    chart["water"]["water"] = 0.5
    chart["water"]["grass"] = 0.5
    chart["water"]["ground"] = 2.0
    chart["water"]["rock"] = 2.0
    chart["water"]["dragon"] = 0.5

    # electric
    chart["electric"]["water"] = 2.0
    chart["electric"]["electric"] = 0.5
    chart["electric"]["grass"] = 0.5
    chart["electric"]["ground"] = 0.0
    chart["electric"]["flying"] = 2.0
    chart["electric"]["dragon"] = 0.5

    # grass
    chart["grass"]["fire"] = 0.5
    chart["grass"]["water"] = 2.0
    chart["grass"]["grass"] = 0.5
    chart["grass"]["poison"] = 0.5
    chart["grass"]["ground"] = 2.0
    chart["grass"]["flying"] = 0.5
    chart["grass"]["bug"] = 0.5
    chart["grass"]["rock"] = 2.0
    chart["grass"]["dragon"] = 0.5
    chart["grass"]["steel"] = 0.5

    # ice
    chart["ice"]["fire"] = 0.5
    chart["ice"]["water"] = 0.5
    chart["ice"]["grass"] = 2.0
    chart["ice"]["ice"] = 0.5
    chart["ice"]["ground"] = 2.0
    chart["ice"]["flying"] = 2.0
    chart["ice"]["dragon"] = 2.0
    chart["ice"]["steel"] = 0.5

    # fighting
    chart["fighting"]["normal"] = 2.0
    chart["fighting"]["ice"] = 2.0
    chart["fighting"]["poison"] = 0.5
    chart["fighting"]["flying"] = 0.5
    chart["fighting"]["psychic"] = 0.5
    chart["fighting"]["bug"] = 0.5
    chart["fighting"]["rock"] = 2.0
    chart["fighting"]["ghost"] = 0.0
    chart["fighting"]["dark"] = 2.0
    chart["fighting"]["steel"] = 2.0

    # poison
    chart["poison"]["grass"] = 2.0
    chart["poison"]["poison"] = 0.5
    chart["poison"]["ground"] = 0.5
    chart["poison"]["rock"] = 0.5
    chart["poison"]["ghost"] = 0.5
    chart["poison"]["steel"] = 0.0

    # ground
    chart["ground"]["fire"] = 2.0
    chart["ground"]["electric"] = 2.0
    chart["ground"]["grass"] = 0.5
    chart["ground"]["poison"] = 2.0
    chart["ground"]["flying"] = 0.0
    chart["ground"]["bug"] = 0.5
    chart["ground"]["rock"] = 2.0
    chart["ground"]["steel"] = 2.0

    # flying
    chart["flying"]["electric"] = 0.5
    chart["flying"]["grass"] = 2.0
    chart["flying"]["fighting"] = 2.0
    chart["flying"]["bug"] = 2.0
    chart["flying"]["rock"] = 0.5
    chart["flying"]["steel"] = 0.5

    # psychic
    chart["psychic"]["fighting"] = 2.0
    chart["psychic"]["poison"] = 2.0
    chart["psychic"]["psychic"] = 0.5
    chart["psychic"]["dark"] = 0.0
    chart["psychic"]["steel"] = 0.5

    # bug
    chart["bug"]["fire"] = 0.5
    chart["bug"]["grass"] = 2.0
    chart["bug"]["fighting"] = 0.5
    chart["bug"]["poison"] = 0.5
    chart["bug"]["flying"] = 0.5
    chart["bug"]["psychic"] = 2.0
    chart["bug"]["ghost"] = 0.5
    chart["bug"]["dark"] = 2.0
    chart["bug"]["steel"] = 0.5

    # rock
    chart["rock"]["fire"] = 2.0
    chart["rock"]["ice"] = 2.0
    chart["rock"]["fighting"] = 0.5
    chart["rock"]["ground"] = 0.5
    chart["rock"]["flying"] = 2.0
    chart["rock"]["bug"] = 2.0
    chart["rock"]["steel"] = 0.5

    # ghost (Gen 3: steel耐性あり = 0.5)
    chart["ghost"]["normal"] = 0.0
    chart["ghost"]["psychic"] = 2.0
    chart["ghost"]["ghost"] = 2.0
    chart["ghost"]["dark"] = 0.5
    chart["ghost"]["steel"] = 0.5

    # dragon
    chart["dragon"]["dragon"] = 2.0
    chart["dragon"]["steel"] = 0.5

    # dark (Gen 3: steel耐性あり = 0.5)
    chart["dark"]["fighting"] = 0.5
    chart["dark"]["psychic"] = 2.0
    chart["dark"]["ghost"] = 2.0
    chart["dark"]["dark"] = 0.5
    chart["dark"]["steel"] = 0.5

    # steel
    chart["steel"]["fire"] = 0.5
    chart["steel"]["water"] = 0.5
    chart["steel"]["electric"] = 0.5
    chart["steel"]["ice"] = 2.0
    chart["steel"]["rock"] = 2.0
    chart["steel"]["steel"] = 0.5

    return chart
end

"""
    save_chart_json(chart::Dict, filepath::String; types::Vector{String}=String[])

タイプ相性表をフォーマットされたJSONファイルとして保存します。
"""
function save_chart_json(chart::Dict{String, Dict{String, Float64}}, filepath::String; types::Vector{String}=String[])
    if isempty(types)
        types = sort(collect(keys(chart)))
    end
    # 順序を保つためOrderedDict風に出力
    lines = String["{"]
    for (i, atk) in enumerate(types)
        push!(lines, "  \"$atk\": {")
        for (j, def) in enumerate(types)
            val = chart[atk][def]
            # 整数表記にできるものは整数で (1 -> 1, 0 -> 0, 0.5 -> 0.5, 2 -> 2)
            val_str = isinteger(val) ? string(Int(val)) : string(val)
            comma = (j < length(types)) ? "," : ""
            push!(lines, "    \"$def\": $val_str$comma")
        end
        comma = (i < length(types)) ? "," : ""
        push!(lines, "  }$comma")
    end
    push!(lines, "}")
    open(filepath, "w") do io
        write(io, join(lines, "\n") * "\n")
    end
end

end # module
