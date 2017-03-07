# This file is a part of Julia. License is MIT: http://julialang.org/license
importall Base

type IntSet32 <: Base.AbstractSet{Int}
    bits::Array{UInt32,1}
    limit::Int
    fill1s::Bool

    IntSet32() = new(zeros(UInt32,1), 32, false)
end
IntSet32(itr) = (s=IntSet32(); for a in itr; push!(s,a); end; s)

eltype(::Type{IntSet32}) = Int64
similar(s::IntSet32) = IntSet32()

function show(io::IO, s::IntSet32)
    print(io, "IntSet32([")
    first = true
    for n in s
        if n > s.limit
            break
        end
        if !first
            print(io, ", ")
        end
        print(io, n)
        first = false
    end
    if s.fill1s
        print(io, ", ..., ", typemax(Int)-1)
    end
    print(io, "])")
end

copy(s::IntSet32) = union!(IntSet32(), s)

function sizehint!(s::IntSet32, top::Integer)
    if top >= s.limit
        lim = ((top+31) & -32)>>>5
        olsz = length(s.bits)
        if olsz < lim
            resize!(s.bits, lim)
            fill = s.fill1s ? UInt32(-1) : UInt32(0)
            for i=(olsz+1):lim; s.bits[i] = fill; end
        end
        s.limit = top
    end
    s
end

function push!(s::IntSet32, n::Integer)
    if n >= s.limit
        if s.fill1s
            return s
        else
            lim = Int(n + div(n,2))
            sizehint!(s, lim)
        end
    elseif n <= 0
        if n < 0
            throw(ArgumentError("IntSet32 elements cannot be negative"))
        else
            # depwarn("storing zero in IntSet32s is deprecated", :push!)
        end
    end
    s.bits[n>>5 + 1] |= (UInt32(1)<<(n&31))
    return s
end

function union!(s::IntSet32, ns)
    for n in ns
        push!(s, n)
    end
    return s
end

function pop!(s::IntSet32, n::Integer, deflt)
    if n >= s.limit
        if s.fill1s
            lim = Int(n + div(n,2))
            sizehint!(s, lim)
        else
            return deflt
        end
    end
    if n <= 0
        if n < 0
            return deflt
        else
            depwarn("stored zeros in IntSet32 is deprecated", :pop!)
        end
    end
    mask = UInt32(1)<<(n&31)
    idx = n>>5 + 1
    b = s.bits[idx]
    if (b&mask)==0; return deflt; end
    s.bits[idx] = b&~mask
    return n
end

function pop!(s::IntSet32, n::Integer)
    if pop!(s, n, n+1) == n+1
        throw(KeyError(n))
    end
    return n
end

# TODO: what should happen when fill1s == true?
pop!(s::IntSet32) = pop!(s, last(s))

function delete!(s::IntSet32, n::Integer)
    pop!(s, n, n)
    return s
end

function setdiff!(s::IntSet32, ns)
    for n in ns
        delete!(s, n)
    end
    return s
end

setdiff(a::IntSet32, b::IntSet32) = setdiff!(copy(a),b)
symdiff(s1::IntSet32, s2::IntSet32) =
    (s1.limit >= s2.limit ? symdiff!(copy(s1), s2) : symdiff!(copy(s2), s1))

function empty!(s::IntSet32)
    fill!(s.bits, 0)
    return s
end

"""
    symdiff!(s, n)

The set `s` is destructively modified to toggle the inclusion of integer `n`.
"""
function symdiff!(s::IntSet32, n::Integer)
    if n >= s.limit
        lim = Int(n + div(n,2))
        sizehint!(s, lim)
    elseif n < 0
        throw(ArgumentError("IntSet32 elements cannot be negative"))
    end
    s.bits[n>>5 + 1] $= (UInt32(1)<<(n&31))
    return s
end

"""
    symdiff!(s, itr)

For each element in `itr`, destructively toggle its inclusion in set `s`.
"""
function symdiff!(s::IntSet32, ns)
   for n in ns
       symdiff!(s, n)
   end
   return s
end

function copy!(to::IntSet32, from::IntSet32)
    if is(to, from)
        return to
    else
        empty!(to)
        return union!(to, from)
    end
end

in(n, s::IntSet32) = n < 0 ? false : (n > typemax(Int) ? s.fill1s : in(convert(Int, n), s))
function in(n::Int, s::IntSet32)
    if n >= s.limit
        # max IntSet32 length is typemax(Int), so highest possible element is
        # typemax(Int)-1
        return s.fill1s && n >= 0 && n < typemax(Int)
    elseif n <= 0
        if n < 0
            return false
        else
            depwarn("stored zeros in IntSet32 is deprecated", :in)
        end
    end
    (s.bits[n>>5 + 1] & (UInt32(1)<<(n&31))) != 0
end

start(s::IntSet32) = Int64(0)
done(s::IntSet32, i) = (!s.fill1s && next(s,i)[1] >= s.limit) || i == typemax(Int)
function next(s::IntSet32, i)
    if i >= s.limit
        n = Int64(i)
    else
        n = Int64(ccall(:bitvector_next, UInt64, (Ptr{UInt32}, UInt64, UInt64), s.bits, i, s.limit))
    end
    (n, n+1)
end

isempty(s::IntSet32) =
    !s.fill1s && ccall(:bitvector_any1, UInt32, (Ptr{UInt32}, UInt64, UInt64), s.bits, 0, s.limit)==0

function first(s::IntSet32)
    n = next(s,0)[1]
    if n >= s.limit
        throw(ArgumentError("set must be non-empty"))
    end
    return n
end

shift!(s::IntSet32) = pop!(s, first(s))

function last(s::IntSet32)
    if !s.fill1s
        for i = length(s.bits):-1:1
            w = s.bits[i]
            if w != 0
                return (i-1)<<5 + (31-leading_zeros(w))
            end
        end
    end
    throw(ArgumentError("set has no last element"))
end

length(s::IntSet32) = Int(ccall(:bitvector_count, UInt64, (Ptr{UInt32}, UInt64, UInt64), s.bits, 0, s.limit)) +
    (s.fill1s ? typemax(Int) - s.limit : 0)


# Math functions
function union!(s::IntSet32, s2::IntSet32)
    if s2.limit > s.limit
        sizehint!(s, s2.limit)
    end
    lim = length(s2.bits)
    for n = 1:lim
        s.bits[n] |= s2.bits[n]
    end
    if s2.fill1s
        for n=lim+1:length(s.bits)
            s.bits[n] = UInt32(-1)
        end
    end
    s.fill1s |= s2.fill1s
    s
end

union(s1::IntSet32) = copy(s1)
union(s1::IntSet32, s2::IntSet32) = (s1.limit >= s2.limit ? union!(copy(s1), s2) : union!(copy(s2), s1))
union(s1::IntSet32, ss::IntSet32...) = union(s1, union(ss...))

function intersect!(s::IntSet32, s2::IntSet32)
    if s2.limit > s.limit
        sizehint!(s, s2.limit)
    end
    lim = length(s2.bits)
    for n = 1:lim
        s.bits[n] &= s2.bits[n]
    end
    if !s2.fill1s
        for n=lim+1:length(s.bits)
            s.bits[n] = UInt32(0)
        end
    end
    s.fill1s &= s2.fill1s
    s
end

intersect(s1::IntSet32) = copy(s1)
intersect(s1::IntSet32, s2::IntSet32) =
    (s1.limit >= s2.limit ? intersect!(copy(s1), s2) : intersect!(copy(s2), s1))
intersect(s1::IntSet32, ss::IntSet32...) = intersect(s1, intersect(ss...))

"""
    symdiff!(s1, s2)

Construct the symmetric difference of sets `s1` and `s2`, storing the result in `s1`.
"""
function symdiff!(s::IntSet32, s2::IntSet32)
    if s2.limit > s.limit
        sizehint!(s, s2.limit)
    end
    lim = length(s2.bits)
    for n = 1:lim
        s.bits[n] $= s2.bits[n]
    end
    if s2.fill1s
        for n=lim+1:length(s.bits)
            s.bits[n] = ~s.bits[n]
        end
    end
    s.fill1s $= s2.fill1s
    s
end

function ==(s1::IntSet32, s2::IntSet32)
    if s1.fill1s != s2.fill1s
        return false
    end
    lim1 = length(s1.bits)
    lim2 = length(s2.bits)
    for i = 1:min(lim1,lim2)
        if s1.bits[i] != s2.bits[i]
            return false
        end
    end
    filln = s1.fill1s ? reinterpret(UInt32, Int32(-1)) : UInt32(0)
    if lim1 > lim2
        for i = lim2:lim1
            if s1.bits[i] != filln
                return false
            end
        end
    else
        for i = lim1+1:lim2
            if s2.bits[i] != filln
                return false
            end
        end
    end
    return true
end

const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
function hash(s::IntSet32, h::UInt)
    h += hashis_seed
    h += hash(s.fill1s)
    filln = s.fill1s ? ~zero(eltype(s.bits)) : zero(eltype(s.bits))
    for x in s.bits
        if x != filln
            h = hash(x, h)
        end
    end
    return h
end

issubset(a::IntSet32, b::IntSet32) = isequal(a, intersect(a,b))
<(a::IntSet32, b::IntSet32) = (a<=b) && !isequal(a,b)
<=(a::IntSet32, b::IntSet32) = issubset(a, b)