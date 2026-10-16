#!/usr/bin/env julia

"""
run.jl: ポケモンのタイプ相性に基づくナッシュ均衡確率を計算するスクリプト

- フェアリータイプ登場後（Gen 6+ / 現代）
- 初代（Gen 1: ゴーストタイプの設計ミスあり、あく・はがねなし）

Usage:
    julia --project=. run.jl          # Gen 6+ と Gen 1 の両方を実行
    julia --project=. run.jl gen6     # Gen 6+ のみ実行
    julia --project=. run.jl gen1     # Gen 1 のみ実行
    julia --project=. run.jl gen3     # Gen 3 のみ実行
"""

using Printf
include("src/TypeChart.jl")
using .TypeChart

"""
結果テーブルを綺麗にフォーマットして出力する関数
"""
function print_nash_table(title::String, labels::Vector{String}, probs::Vector{Float64}; nonzero_only::Bool=false, threshold::Float64=1e-5)
    # ペアにして確率の降順でソート
    pairs = [(labels[i], probs[i]) for i in 1:length(labels)]
    sort!(pairs, by = x -> x[2], rev = true)

    if nonzero_only
        filter!(x -> x[2] > threshold, pairs)
    end

    println("\n" * title * ":")
    if isempty(pairs)
        println("  (該当なし)")
        return
    end

    # 最大ラベル長を計算
    max_label_len = maximum(length(p[1]) for p in pairs)
    col1_len = max(max_label_len, 4)

    header = @sprintf("  %-*s  %12s", col1_len, "type", "nash")
    divider = "  " * "-"^col1_len * "  " * "-"^12
    println(header)
    println(divider)

    for (lab, p) in pairs
        @printf("  %-*s  %12.6f\n", col1_len, lab, p)
    end
end

"""
指定されたタイプ相性データに対してナッシュ均衡を計算・表示
"""
function analyze_chart(tc::TypeChartData)
    separator = "="^70
    println("\n" * separator)
    println("  分析対象: $(tc.name)")
    println("  タイプ数: $(length(tc.types))")
    println(separator)

    # 1. 単タイプ (Symmetric)
    s_types = single_types(tc)
    s_names = [combination_name(t) for t in s_types]
    s_matrix = symmetric_matchup_matrix(tc, s_types)
    s_nash = nash(s_matrix)
    print_nash_table("Single type Nash probabilities", s_names, s_nash)

    # 2. 複合タイプ (Symmetric)
    d_types = dual_types(tc)
    d_names = [combination_name(t) for t in d_types]
    d_matrix = symmetric_matchup_matrix(tc, d_types)
    d_nash = nash(d_matrix)
    print_nash_table("Dual type Nash probabilities (nonzero only)", d_names, d_nash; nonzero_only=true)

    # 3. 攻撃側単タイプ vs 防御側複合タイプ (Asymmetric Zero-Sum Game)
    asym_matrix = asymmetric_matchup_matrix(tc, s_types, d_types)
    attacker_nash, defender_nash, game_val = nash_zerosum(asym_matrix)

    @printf("\n[Asymmetric Game] Minimax Value (Game Value): %.4f\n", game_val)
    print_nash_table("Single type attacker Nash probabilities", s_names, attacker_nash)
    print_nash_table("Dual type defender Nash probabilities (nonzero only)", d_names, defender_nash; nonzero_only=true)
end

function main()
    target = lowercase(get(ARGS, 1, "all"))

    if target in ("all", "both")
        println("=== ポケモンタイプ相性 ナッシュ均衡分析 (Julia版) ===")
        tc6 = load_chart_gen6()
        tc3 = load_chart_gen3()
        tc1 = load_chart_gen1()

        analyze_chart(tc6)
        analyze_chart(tc3)
        analyze_chart(tc1)

        print_comparison_summary(tc1, tc3, tc6)
    elseif target in ("gen6", "gen6+", "fairy", "modern")
        analyze_chart(load_chart_gen6())
    elseif target in ("gen3", "gen3-5", "ruby", "gen4", "gen5")
        analyze_chart(load_chart_gen3())
    elseif target in ("gen1", "first", "red", "bug")
        analyze_chart(load_chart_gen1())
    else
        println("未知の世代引数: $target")
        println("使用可能な引数: all, gen6, gen3 (または gen3-5), gen1")
        exit(1)
    end
end

"""
3世代（Gen 1 vs Gen 3-5 vs Gen 6+）の比較サマリー表を出力
"""
function print_comparison_summary(tc1::TypeChartData, tc3::TypeChartData, tc6::TypeChartData)
    println("\n" * "="^78)
    println("  世代間 単タイプ Nash 均衡確率 比較サマリー")
    println("="^78)

    # 全18タイプ
    all_types = TYPES_GEN6

    # 各世代の単タイプNash
    m1 = symmetric_matchup_matrix(tc1, single_types(tc1))
    p1_raw = nash(m1)
    dict1 = Dict(tc1.types[i] => p1_raw[i] for i in 1:length(tc1.types))

    m3 = symmetric_matchup_matrix(tc3, single_types(tc3))
    p3_raw = nash(m3)
    dict3 = Dict(tc3.types[i] => p3_raw[i] for i in 1:length(tc3.types))

    m6 = symmetric_matchup_matrix(tc6, single_types(tc6))
    p6_raw = nash(m6)
    dict6 = Dict(tc6.types[i] => p6_raw[i] for i in 1:length(tc6.types))

    println(@sprintf("  %-10s  %12s  %12s  %12s", "type", "Gen 1 (初代)", "Gen 3-5", "Gen 6+ (現代)"))
    println("  " * "-"^10 * "  " * "-"^12 * "  " * "-"^12 * "  " * "-"^12)

    for t in all_types
        v1 = get(dict1, t, NaN)
        v3 = get(dict3, t, NaN)
        v6 = get(dict6, t, NaN)

        s1 = isnan(v1) ? "     -      " : @sprintf("%12.4f", v1)
        s3 = isnan(v3) ? "     -      " : @sprintf("%12.4f", v3)
        s6 = @sprintf("%12.4f", v6)

        println(@sprintf("  %-10s  %s  %s  %s", t, s1, s3, s6))
    end
    println("="^78)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
