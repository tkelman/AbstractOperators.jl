export MatrixOp

"""
`MatrixOp(domainType=Float64::Type, dim_in::Tuple, A::AbstractMatrix)`

`MatrixOp(A::AbstractMatrix)`

`MatrixOp(A::AbstractMatrix, n_colons)`

Creates a `LinearOperator` which, when multiplied with a vector `x::AbstractVector`, returns the product `A*x`.

The input `x` can be also a matrix: the number of columns must be given either in the second entry of `dim_in::Tuple` or using the constructor `MatrixOp(A::AbstractMatrix, n_colons)`.

```julia
julia> MatrixOp(Float64,(10,),randn(20,10))
▒  ℝ^10 -> ℝ^20 

julia> MatrixOp(randn(20,10))
▒  ℝ^10 -> ℝ^20

julia> MatrixOp(Float64,(10,20),randn(20,10))
▒  ℝ^(10, 20) -> ℝ^(20, 20)

julia> MatrixOp(randn(20,10),4)
▒  ℝ^(10, 4) -> ℝ^(20, 4)

```

"""

immutable MatrixOp{T, M <: AbstractMatrix{T}} <: LinearOperator
	A::M
	n_col_in::Integer
end

# Constructors

##TODO decide what to do when domainType is given, with conversion one loses pointer to data...
###standard constructor Operator{N}(DomainType::Type, DomainDim::NTuple{N,Int})
function MatrixOp{N, M <: AbstractMatrix}(DomainType::Type, DomainDim::NTuple{N,Int}, A::M)  
	N > 2 && error("cannot multiply a Matrix by a n-dimensional Variable with n > 2") 
	size(A,2) != DomainDim[1] && error("wrong input dimensions")
	if N == 1
		MatrixOp{DomainType, M}(A, 1)
	else
		MatrixOp{DomainType, M}(A, DomainDim[2])
	end
end
###

MatrixOp{M <: AbstractMatrix}(A::M) = MatrixOp{eltype(A), M}(A, 1)
MatrixOp{M <: AbstractMatrix}(T::Type, A::M) = MatrixOp{T, M}(A, 1)
MatrixOp{M <: AbstractMatrix}(A::M, n::Integer) = MatrixOp{eltype(A), M}(A, n)
MatrixOp{M <: AbstractMatrix}(T::Type, A::M, n::Integer) = MatrixOp{T, M}(A, n)

import Base: convert
convert{T,M<:AbstractMatrix{T}}(::Type{LinearOperator}, L::M) = MatrixOp{T,M}(L,1)
convert{T,M<:AbstractMatrix{T}}(::Type{LinearOperator}, L::M, n::Integer) = MatrixOp{T,M}(L, n)

# Mappings

A_mul_B!{M, T}(y::AbstractArray, L::MatrixOp{M, T}, b::AbstractArray) = A_mul_B!(y, L.A, b)
Ac_mul_B!{M, T}(y::AbstractArray, L::MatrixOp{M, T}, b::AbstractArray) = Ac_mul_B!(y, L.A, b)

# Properties

domainType{T, M}(L::MatrixOp{T, M}) = T
codomainType{T, M}(L::MatrixOp{T, M}) = T

function size(L::MatrixOp)
	if L.n_col_in == 1
		( (size(L.A, 1),), (size(L.A, 2),) )
	else
		( (size(L.A, 1), L.n_col_in), (size(L.A, 2), L.n_col_in) )
	end
end

fun_name(L::MatrixOp) = "▒"

is_diagonal(L::MatrixOp) = isdiag(L.A)
is_full_row_rank(L::MatrixOp) = rank(L.A) == size(L.A, 1)
is_full_column_rank(L::MatrixOp) = rank(L.A) == size(L.A, 2)
