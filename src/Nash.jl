module Nash

export nash, nash_symmetric, nash_zerosum

using JuMP
using HiGHS
using LinearAlgebra

"""
    nash_symmetric(matrix::Matrix{Float64}) -> Vector{Float64}

対称ゼロサムゲーム（matrix == -matrix'）のナッシュ均衡混合戦略を求めます。
Pythonの `nash.py` と同じく線形計画法（LP）を用いて解を求めます。
"""
function nash_symmetric(matrix::Matrix{Float64})::Vector{Float64}
    n, m = size(matrix)
    @assert n == m "Matrix must be square, got $(n)x$(m)"
    @assert n > 1 "Matrix dimension must be > 1"
    @assert isapprox(matrix, -matrix', atol=1e-5) "Matrix must be antisymmetric (A = -A')"

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, 0.0 <= x[1:n] <= 1.0)
    @constraint(model, sum(x) == 1.0)
    @constraint(model, matrix * x .<= 0.0)
    @objective(model, Min, 0.0)

    optimize!(model)
    @assert is_solved_and_feasible(model) "Failed to find feasible symmetric Nash equilibrium"

    sol = value.(x)
    sol .= max.(sol, 0.0)
    total = sum(sol)
    if total > 0
        sol ./= total
    end
    return sol
end

# nash は nash_symmetric のエイリアス
const nash = nash_symmetric

"""
    nash_zerosum(payoff::Matrix{Float64}) -> (p::Vector{Float64}, q::Vector{Float64}, value::Float64)

一般の二人ゼロサムゲームのナッシュ均衡を線形計画法で求めます。
- `payoff[i, j]`: 行プレイヤー（攻撃側）が戦略i、列プレイヤー（防御側）が戦略jを選んだときの行プレイヤーの利得。
- 戻り値:
  - `p`: 行プレイヤーの最適混合戦略
  - `q`: 列プレイヤーの最適混合戦略
  - `value`: ゲームの均衡利得値（Maximin値 / Minimax値）
"""
function nash_zerosum(payoff::Matrix{Float64})::Tuple{Vector{Float64}, Vector{Float64}, Float64}
    n, m = size(payoff)

    # 1. 行プレイヤー（攻撃側）のLP: 利得 v の最大化
    model_atk = Model(HiGHS.Optimizer)
    set_silent(model_atk)
    @variable(model_atk, p[1:n] >= 0.0)
    @variable(model_atk, v)
    @constraint(model_atk, sum(p) == 1.0)
    @constraint(model_atk, [j = 1:m], sum(p[i] * payoff[i, j] for i in 1:n) >= v)
    @objective(model_atk, Max, v)

    optimize!(model_atk)
    @assert is_solved_and_feasible(model_atk) "Failed to solve attacker LP in zero-sum game"
    p_opt = value.(p)
    game_val = value(v)
    p_opt .= max.(p_opt, 0.0)
    sum_p = sum(p_opt)
    if sum_p > 0
        p_opt ./= sum_p
    end

    # 2. 列プレイヤー（防御側）のLP: 相手利得 u の最小化
    model_def = Model(HiGHS.Optimizer)
    set_silent(model_def)
    @variable(model_def, q[1:m] >= 0.0)
    @variable(model_def, u)
    @constraint(model_def, sum(q) == 1.0)
    @constraint(model_def, [i = 1:n], sum(payoff[i, j] * q[j] for j in 1:m) <= u)
    @objective(model_def, Min, u)

    optimize!(model_def)
    @assert is_solved_and_feasible(model_def) "Failed to solve defender LP in zero-sum game"
    q_opt = value.(q)
    q_opt .= max.(q_opt, 0.0)
    sum_q = sum(q_opt)
    if sum_q > 0
        q_opt ./= sum_q
    end

    return (p_opt, q_opt, game_val)
end

end # module
