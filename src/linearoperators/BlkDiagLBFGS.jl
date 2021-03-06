
type BlkDiagLBFGS{M, N, R<:Real, A <:NTuple{N,AbstractArray}, B <:NTuple{M,A}} <: LinearOperator
	currmem::Int
	curridx::Int
	s::A
	y::A
	s_m::B
	y_m::B
	ys_m::Array{Float64,1}
	alphas::Array{Float64,1}
	H::R
end

#constructors
#default
function LBFGS{N}(T::NTuple{N,Type}, dim::NTuple{N,NTuple}, M::Int)
	s_m = tuple([deepzeros(T,dim) for i = 1:M]...)
	y_m = tuple([deepzeros(T,dim) for i = 1:M]...)
	s = deepzeros(T,dim)
	y = deepzeros(T,dim)
	R = real(T[1])
	ys_m = zeros(R, M)
	alphas = zeros(R, M)
	BlkDiagLBFGS{M,N,R,typeof(s),typeof(s_m)}(0, 0, s, y, s_m, y_m, ys_m, alphas, 1.) 
end

LBFGS{N}(x::NTuple{N,AbstractArray},M::Int64) = LBFGS(eltype.(x),size.(x),M)

#mappings

@generated function update!{M,N,R,A,B}(L::BlkDiagLBFGS{M,N,R,A,B}, 
				     x::A, 
				     x_prev::A, 
				     gradx::A, 
				     gradx_prev::A)

	ex = :(ys = 0.)
	for i = 1:N
		ex = :($ex; ys += update_s_y(L.s[$i],L.y[$i],x[$i],x_prev[$i],gradx[$i],gradx_prev[$i]))
	end
	ex2 = :(yty = 0.)
	for i = 1:N
		ex2 = :($ex2; yty += update_s_m_y_m(L.s_m[L.curridx][$i],L.y_m[L.curridx][$i],
				      L.s[$i],L.y[$i] ))
	end

	ex =  quote 
		$ex
		if ys > 0
			L.curridx += 1
			if L.curridx > M L.curridx = 1 end
			L.currmem += 1
			if L.currmem > M L.currmem = M end

			$ex2
			L.ys_m[L.curridx] = ys
			L.H = ys/sum(yty) 
		end
		return L
	end
end

function update_s_y{A}(s::A, y::A, x::A, x_prev::A, gradx::A, gradx_prev::A) 
	s .= (-).(x, x_prev)
	y .= (-).(gradx, gradx_prev)
	ys = real(vecdot(s,y))
	return ys
end

function update_s_m_y_m{A}(s_m::A,y_m::A,s::A,y::A) 
	s_m .=  s
	y_m .=  y

	yty = real(vecdot(y,y))
	return yty
end

function A_mul_B!{M, N, R, A, B}(d::A, L::BlkDiagLBFGS{M,N,R,A,B}, gradx::A)
	for i = 1:N
		d[i] .= (-).(gradx[i])
	end
	idx = loop1!(d,L)
	for i = 1:N
		d[i] .= (*).(L.H, d[i])
	end
	d = loop2!(d,idx,L)
end

function loop1!{M, N, R, A, B}(d::A, L::BlkDiagLBFGS{M,N,R,A,B})
	idx = L.curridx
	for i=1:L.currmem
		L.alphas[idx] = sum(real.(vecdot.(L.s_m[idx], d)))

		L.alphas[idx] /= L.ys_m[idx]
		for ii = 1:N
			d[ii] .-= L.alphas[idx].*L.y_m[idx][ii]
		end
		idx -= 1
		if idx == 0 idx = M end
	end
	return idx
end

function loop2!{M, N, R, A, B}(d::A, idx::Int, L::BlkDiagLBFGS{M,N,R,A,B})
	for i=1:L.currmem
		idx += 1
		if idx > M idx = 1 end
		beta = sum(real.(vecdot.(L.y_m[idx], d)))
		beta /= L.ys_m[idx]
		for ii = 1:N
			d[ii] .-= (beta-L.alphas[idx]).*L.s_m[idx][ii]
		end
	end
	return d
end

function reset(L::BlkDiagLBFGS)
	L.currmem = 0
	L.curridx = 0
end

# Properties

domainType(L::BlkDiagLBFGS) = eltype.(L.s)
codomainType(L::BlkDiagLBFGS) = eltype.(L.s)

fun_name(A::BlkDiagLBFGS) = "LBFGS"
size(A::BlkDiagLBFGS) = (size.(A.s), size.(A.s))
