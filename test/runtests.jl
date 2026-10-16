using Test
using LinearAlgebra

# モジュールの読み込み
include("../src/TypeChart.jl")
using .TypeChart

@testset "TypeChart.jl Tests" begin
    @testset "Rock-Paper-Scissors Nash" begin
        # じゃんけん行列
        # グー(1), チョキ(2), パー(3)
        RPS = [
             0.0 -1.0  1.0;
             1.0  0.0 -1.0;
            -1.0  1.0  0.0
        ]
        sol = nash(RPS)
        @test length(sol) == 3
        @test isapprox(sol, [1/3, 1/3, 1/3], atol=1e-4)
    end

    @testset "Gen 1 (初代) 相性テスト" begin
        tc1 = load_chart_gen1()
        @test length(tc1.types) == 15
        @test !("dark" in tc1.types)
        @test !("steel" in tc1.types)
        @test !("fairy" in tc1.types)

        # ★初代のゴースト設計ミス
        @test get_multiplier(tc1, "ghost", "psychic") == 0.0
        # 初代のエスパー→ゴーストは等倍
        @test get_multiplier(tc1, "psychic", "ghost") == 1.0
        # 初代の虫↔毒は互いに抜群
        @test get_multiplier(tc1, "bug", "poison") == 2.0
        @test get_multiplier(tc1, "poison", "bug") == 2.0
        # 初代の氷→炎は等倍
        @test get_multiplier(tc1, "ice", "fire") == 1.0
        # ノーマルとゴーストは互いに無効
        @test get_multiplier(tc1, "normal", "ghost") == 0.0
        @test get_multiplier(tc1, "ghost", "normal") == 0.0

        # 対称マッチアップ行列の反対称性
        s_types = single_types(tc1)
        mat = symmetric_matchup_matrix(tc1, s_types)
        @test isapprox(mat, -mat', atol=1e-6)

        # Nash均衡が計算でき、確率の和が1
        p = nash(mat)
        @test isapprox(sum(p), 1.0, atol=1e-5)
        @test all(p .>= -1e-6)
    end

    @testset "Gen 6+ (フェアリー登場後) 相性テスト" begin
        tc6 = load_chart_gen6()
        @test length(tc6.types) == 18
        @test "fairy" in tc6.types
        @test "steel" in tc6.types
        @test "dark" in tc6.types

        # フェアリー攻撃
        @test get_multiplier(tc6, "fairy", "dragon") == 2.0
        @test get_multiplier(tc6, "fairy", "fighting") == 2.0
        @test get_multiplier(tc6, "fairy", "dark") == 2.0
        @test get_multiplier(tc6, "fairy", "fire") == 0.5
        @test get_multiplier(tc6, "fairy", "poison") == 0.5
        @test get_multiplier(tc6, "fairy", "steel") == 0.5

        # フェアリー防御
        @test get_multiplier(tc6, "dragon", "fairy") == 0.0
        @test get_multiplier(tc6, "poison", "fairy") == 2.0
        @test get_multiplier(tc6, "steel", "fairy") == 2.0
        @test get_multiplier(tc6, "fighting", "fairy") == 0.5
        @test get_multiplier(tc6, "bug", "fairy") == 0.5
        @test get_multiplier(tc6, "dark", "fairy") == 0.5

        # 鋼のゴースト・悪耐性削除（等倍）
        @test get_multiplier(tc6, "ghost", "steel") == 1.0
        @test get_multiplier(tc6, "dark", "steel") == 1.0

        # ゴースト→エスパーは2倍（バグ修正後）
        @test get_multiplier(tc6, "ghost", "psychic") == 2.0

        # 虫・毒の相性（通常仕様）
        @test get_multiplier(tc6, "bug", "poison") == 0.5
        @test get_multiplier(tc6, "poison", "bug") == 1.0

        # 氷→炎（半減仕様）
        @test get_multiplier(tc6, "ice", "fire") == 0.5

        # 対称マッチアップ行列
        s_types = single_types(tc6)
        mat = symmetric_matchup_matrix(tc6, s_types)
        @test isapprox(mat, -mat', atol=1e-6)

        p = nash(mat)
        @test isapprox(sum(p), 1.0, atol=1e-5)
        @test all(p .>= -1e-6)
    end

    @testset "非対称ゲーム (ゼロサムLP)" begin
        tc6 = load_chart_gen6()
        s_types = single_types(tc6)
        d_types = dual_types(tc6)
        asym_mat = asymmetric_matchup_matrix(tc6, s_types, d_types)
        @test size(asym_mat) == (18, 18 + 18*17/2)

        p_atk, q_def, val = nash_zerosum(asym_mat)
        @test isapprox(sum(p_atk), 1.0, atol=1e-5)
        @test isapprox(sum(q_def), 1.0, atol=1e-5)
        @test all(p_atk .>= -1e-6)
        @test all(q_def .>= -1e-6)
        @test val > 0.0
    end
end
