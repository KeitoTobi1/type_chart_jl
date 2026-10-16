module Matchup

export TypeCombination, TypeChartData
export get_multiplier, get_multiplier_for_combination, get_best_multiplier
export compare, matchup
export symmetric_matchup_matrix, asymmetric_matchup_matrix
export single_types, dual_types, combination_name

const TypeCombination = Tuple{Vararg{String}}

"""
    TypeChartData

タイプ相性データ構造体。
- `name`: 世代名・バージョン名（例: "Gen 1 (初代)", "Gen 6+ (フェアリー登場後)"）
- `types`: 使用タイプのリスト
- `chart`: `chart[attacker][defender]` = 倍率
"""
struct TypeChartData
    name::String
    types::Vector{String}
    chart::Dict{String, Dict{String, Float64}}
end

"""
    get_multiplier(tc::TypeChartData, attacker_type::String, defender_type::String) -> Float64

攻撃タイプから防御タイプへの相性倍率を返します。
"""
function get_multiplier(tc::TypeChartData, attacker_type::String, defender_type::String)::Float64
    return tc.chart[attacker_type][defender_type]
end

"""
    get_multiplier_for_combination(tc::TypeChartData, attacker_type::String, defender_types::TypeCombination) -> Float64

単一の攻撃タイプが複合タイプの防御側に与えるダメージ倍率（各タイプの倍率の積）を返します。
"""
function get_multiplier_for_combination(tc::TypeChartData, attacker_type::String, defender_types::TypeCombination)::Float64
    res = 1.0
    for d in defender_types
        res *= get_multiplier(tc, attacker_type, d)
    end
    return res
end

"""
    get_best_multiplier(tc::TypeChartData, attacker::TypeCombination, defender::TypeCombination) -> Float64

攻撃側が持つタイプのうち、防御側に対して最も倍率が高い攻撃を繰り出した場合の倍率を返します。
"""
function get_best_multiplier(tc::TypeChartData, attacker::TypeCombination, defender::TypeCombination)::Float64
    best = 0.0
    for atk in attacker
        mult = get_multiplier_for_combination(tc, atk, defender)
        if mult > best
            best = mult
        end
    end
    return best
end

"""
    compare(x::Float64, y::Float64) -> Int

x < y なら -1、x > y なら 1、x == y なら 0 を返します。
"""
function compare(x::Float64, y::Float64)::Int
    if x < y
        return -1
    elseif x > y
        return 1
    else
        return 0
    end
end

"""
    matchup(tc::TypeChartData, attacker::TypeCombination, defender::TypeCombination) -> Int

攻撃側と防御側が互いに最大有効技を繰り出した時の勝敗を判定します。
- 1: 攻撃側有利 (attacker の最大倍率 > defender の最大倍率)
- -1: 防御側有利 (attacker の最大倍率 < defender の最大倍率)
- 0: 引き分け
"""
function matchup(tc::TypeChartData, attacker::TypeCombination, defender::TypeCombination)::Int
    return compare(get_best_multiplier(tc, attacker, defender),
                   get_best_multiplier(tc, defender, attacker))
end

"""
    symmetric_matchup_matrix(tc::TypeChartData, type_combinations::Vector{TypeCombination}) -> Matrix{Float64}

タイプ組み合わせ間の対称マッチアップ行列（勝敗判定値 +1, -1, 0 からなる反対称行列）を返します。
"""
function symmetric_matchup_matrix(tc::TypeChartData, type_combinations::Vector{TypeCombination})::Matrix{Float64}
    n = length(type_combinations)
    mat = zeros(Float64, n, n)
    for i in 1:n
        for j in 1:n
            mat[i, j] = Float64(matchup(tc, type_combinations[i], type_combinations[j]))
        end
    end
    return mat
end

"""
    asymmetric_matchup_matrix(tc::TypeChartData, attacker_types::Vector{TypeCombination}, defender_types::Vector{TypeCombination}) -> Matrix{Float64}

攻撃側タイプ組み合わせが防御側タイプ組み合わせに与える最善ダメージ倍率の行列を返します。
"""
function asymmetric_matchup_matrix(tc::TypeChartData,
                                  attacker_types::Vector{TypeCombination},
                                  defender_types::Vector{TypeCombination})::Matrix{Float64}
    n = length(attacker_types)
    m = length(defender_types)
    mat = zeros(Float64, n, m)
    for i in 1:n
        for j in 1:m
            mat[i, j] = get_best_multiplier(tc, attacker_types[i], defender_types[j])
        end
    end
    return mat
end

"""
    single_types(tc::TypeChartData) -> Vector{TypeCombination}

全タイプの単タイプタプルのリストを返します。
"""
function single_types(tc::TypeChartData)::Vector{TypeCombination}
    return [(t,) for t in tc.types]
end

"""
    dual_types(tc::TypeChartData) -> Vector{TypeCombination}

単タイプと、重複のない複合タイプの全リストを返します（Pythonの `t1 < t2` のアルファベット順の複合タイプに準拠）。
"""
function dual_types(tc::TypeChartData)::Vector{TypeCombination}
    singles = single_types(tc)
    duals = TypeCombination[]
    for t1 in tc.types
        for t2 in tc.types
            if t1 < t2
                push!(duals, (t1, t2))
            end
        end
    end
    return vcat(singles, duals)
end

"""
    combination_name(c::TypeCombination) -> String

タイプ組み合わせの表示名を返します（例: "fire/flying"）。
"""
function combination_name(c::TypeCombination)::String
    return join(c, "/")
end

end # module
