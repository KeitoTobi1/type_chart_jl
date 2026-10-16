module TypeChart

export Charts, Matchup, Nash
export TypeCombination, TypeChartData
export get_multiplier, get_multiplier_for_combination, get_best_multiplier
export compare, matchup
export symmetric_matchup_matrix, asymmetric_matchup_matrix
export single_types, dual_types, combination_name
export nash, nash_symmetric, nash_zerosum
export load_chart_gen1, load_chart_gen6, load_chart_gen3, load_chart_from_json, export_json_charts
export TYPES_GEN1, TYPES_GEN6, TYPES_GEN3

include("Charts.jl")
include("Matchup.jl")
include("Nash.jl")

using .Charts
using .Matchup
using .Nash
using JSON

"""
    load_chart_gen1() -> TypeChartData

初代（Gen 1: 赤・緑・青・ピカチュウ）のタイプ相性データを作成して返します。
- 15タイプ（あく・はがね・フェアリーなし）
- 初代のゴースト設計ミスあり（ゴースト技 -> エスパータイプ = 0.0）
- 初代仕様: 虫↔毒は互いに抜群(2.0)、氷技は炎タイプに等倍(1.0)
"""
function load_chart_gen1()::TypeChartData
    return TypeChartData(
        "Gen 1 (初代: ゴースト設計ミスあり・あく/はがねなし)",
        TYPES_GEN1,
        build_chart_gen1()
    )
end

"""
    load_chart_gen6() -> TypeChartData

フェアリータイプ登場後（Gen 6+ / 現代）のタイプ相性データを作成して返します。
- 18タイプ（フェアリータイプ含む）
- はがねのゴースト・あく耐性削除（等倍化）
"""
function load_chart_gen6()::TypeChartData
    return TypeChartData(
        "Gen 6+ (フェアリータイプ登場後・現代相性)",
        TYPES_GEN6,
        build_chart_gen6()
    )
end

"""
    load_chart_gen3() -> TypeChartData

第3世代（Gen 3: ルビー・サファイア）のタイプ相性データを作成して返します。
（元リポジトリのPythonコードの互換性のためのデータ）
"""
function load_chart_gen3()::TypeChartData
    return TypeChartData(
        "Gen 3 (ルビー・サファイア期相性)",
        TYPES_GEN3,
        build_chart_gen3()
    )
end

"""
    load_chart_from_json(filepath::String, name::String="Custom") -> TypeChartData

指定されたJSONファイルからタイプ相性データを読み込みます。
"""
function load_chart_from_json(filepath::String, name::String="Custom")::TypeChartData
    raw = JSON.parsefile(filepath)
    types = collect(keys(raw))
    chart = Dict{String, Dict{String, Float64}}()
    for (atk, def_dict) in raw
        chart[atk] = Dict{String, Float64}()
        for (def, val) in def_dict
            chart[atk][def] = Float64(val)
        end
    end
    return TypeChartData(name, types, chart)
end

"""
    export_json_charts(data_dir::String="data")

初代 (Gen 1) および フェアリー登場後 (Gen 6+) のタイプ相性をJSONファイルとして書き出します。
"""
function export_json_charts(data_dir::String="data")
    mkpath(data_dir)
    save_chart_json(build_chart_gen1(), joinpath(data_dir, "type_chart_gen1.json"); types=TYPES_GEN1)
    save_chart_json(build_chart_gen6(), joinpath(data_dir, "type_chart_gen6.json"); types=TYPES_GEN6)
    save_chart_json(build_chart_gen3(), joinpath(data_dir, "type_chart_gen3.json"); types=TYPES_GEN3)
    println("Exported type charts to $data_dir/")
end

end # module
