export MatrixMul


"""
`MatrixMul(domainType=Float64::Type, dim_in::Tuple, b::AbstractVector)`

`MatrixMul(b::AbstractVector, number_of_rows::Int)`

Creates a `LinearOperator` which, when multiplied with a matrix `X::AbstractMatrix`, returns the product `X*b`.

```julia
julia> op = MatrixMul(Float64,(3,4),ones(4))
(⋅)b  ℝ^(3, 4) -> ℝ^3 

julia> op = MatrixMul(ones(4),3)
(⋅)b  ℝ^(3, 4) -> ℝ^3

julia> op*ones(3,4)
3-element Array{Float64,1}:
 4.0
 4.0
 4.0

```

"""

immutable MatrixMul{T, A <: AbstractVector, B <:RowVector} <: LinearOperator
	b::A
	bt::B
	n_row_in::Integer
end

##TODO decide what to do when domainType is given, with conversion one loses pointer to data...
# Constructors
function MatrixMul{A <: AbstractVector}(DomainType::Type,
					DomainDim::Tuple{Int,Int}, b::A)  
	bt = b'
	MatrixMul{DomainType, A, typeof(bt)}(b,bt,DomainDim[1])
end

MatrixMul{T,A<:AbstractVector{T}}(b::A, n_row_in::Int) = MatrixMul(T,(n_row_in,length(b)),b) 

# Mappings
A_mul_B!{T,A}(y::AbstractVector{T}, L::MatrixMul{T,A}, b::AbstractMatrix{T} ) = A_mul_B!(y,b,L.b)
function Ac_mul_B!{T,A,B}(y::AbstractMatrix{T}, L::MatrixMul{T,A,B}, b::AbstractVector{T} ) 
	y .= L.bt.*b
end

# Properties
domainType{T, A}(L::MatrixMul{T, A}) = T
codomainType{T, A}(L::MatrixMul{T, A}) = T

fun_name(L::MatrixMul) = "(⋅)b"

size(L::MatrixMul) = (L.n_row_in,),(L.n_row_in, length(L.b))

#TODO

#is_full_row_rank(L::MatrixMul) = 
#is_full_column_rank(L::MatrixOp) =
