struct IntSet32 <: AbstractSet{Int}
    bits::BitVector
    IntSet32() = new(falses(32))
end
IntSet32(itr) = union!(IntSet32(), itr)

eltype(::Type{IntSet32}) = Int
similar(s::IntSet32) = IntSet32()
copy(s1::IntSet32) = copy!(IntSet32(), s1)
function copy!(dest::IntSet32, src::IntSet32)
    resize!(dest.bits, length(src.bits))
    copy!(dest.bits, src.bits)
    dest
end
eltype(s::IntSet32) = Int
sizehint!(s::IntSet32, n::Integer) = (_resize0!(s.bits, max(n, length(s.bits))); s)

# An internal function for setting the inclusion bit for a given integer n >= 0
@inline function _setint!(s::IntSet32, idx::Integer, b::Bool)
    if idx > length(s.bits)
        b || return s # setting a bit to zero outside the set's bits is a no-op
        newlen = idx + idx>>1 # This operation may overflow; we want saturation
        _resize0!(s.bits, ifelse(newlen<0, typemax(Int), newlen))
    end
    @inbounds s.bits[idx] = b
    s
end

# An internal function to resize a bitarray and ensure the newly allocated
# elements are zeroed (will become unnecessary if this behavior changes)
@inline function _resize0!(b::BitVector, newlen::Integer)
    len = length(b)
    resize!(b, newlen)
    len < newlen && @inbounds b[len+1:newlen] = false # resize! gives dirty memory
    b
end

# An internal function that takes a pure function `f` and maps across two BitArrays
# allowing the lengths to be different and altering b1 with the result
function _matched_map!(f, b1::BitArray, b2::BitArray)
    l1, l2 = length(b1), length(b2)
    if l1 == l2
        map!(f, b1, b1, b2)
    elseif l1 < l2
        _resize0!(b1, l2)
        map!(f, b1, b1, b2)
    elseif l1 > l2
        if f(false, false) == f(true, false) == false
            # We don't need to worry about the trailing bits — they're all false
            resize!(b1, l2)
            map!(f, b1, b1, b2)
        else
            # We transiently extend b2 — as IntSet32 internal storage this is unobservable
            _resize0!(b2, l1)
            map!(f, b1, b1, b2)
            resize!(b2, l2)
        end
    end
    b1
end

@noinline _throw_intset32_bounds_err() = throw(ArgumentError("elements of IntSet32 must be between 1 and typemax(Int)"))
@noinline _throw_keyerror(n) = throw(KeyError(n))

@inline function push!(s::IntSet32, n::Integer)
    0 < n <= typemax(Int) || _throw_intset32_bounds_err()
    _setint!(s, n, true)
end
push!(s::IntSet32, ns::Integer...) = (for n in ns; push!(s, n); end; s)

@inline function pop!(s::IntSet32)
    pop!(s, last(s))
end
@inline function pop!(s::IntSet32, n::Integer)
    n in s ? (_delete!(s, n); n) : _throw_keyerror(n)
end
@inline function pop!(s::IntSet32, n::Integer, default)
    n in s ? (_delete!(s, n); n) : default
end
@inline _delete!(s::IntSet32, n::Integer) = _setint!(s, n, false)
@inline delete!(s::IntSet32, n::Integer) = n < 0 ? s : _delete!(s, n)
shift!(s::IntSet32) = pop!(s, first(s))

empty!(s::IntSet32) = (fill!(s.bits, false); s)
isempty(s::IntSet32) = !any(s.bits)

# Mathematical set functions: union!, intersect!, setdiff!, symdiff!

union(s::IntSet32) = copy(s)
union(s1::IntSet32, s2::IntSet32) = union!(copy(s1), s2)
union(s1::IntSet32, ss::IntSet32...) = union(s1, union(ss...))
union(s::IntSet32, ns) = union!(copy(s), ns)
union!(s::IntSet32, ns) = (for n in ns; push!(s, n); end; s)
function union!(s1::IntSet32, s2::IntSet32)
    _matched_map!(|, s1.bits, s2.bits)
    s1
end

intersect(s1::IntSet32) = copy(s1)
intersect(s1::IntSet32, ss::IntSet32...) = intersect(s1, intersect(ss...))
function intersect(s1::IntSet32, ns)
    s = IntSet32()
    for n in ns
        n in s1 && push!(s, n)
    end
    s
end
intersect(s1::IntSet32, s2::IntSet32) =
    (length(s1.bits) >= length(s2.bits) ? intersect!(copy(s1), s2) : intersect!(copy(s2), s1))
"""
    intersect!(s1::IntSet32, s2::IntSet32)
Intersects sets `s1` and `s2` and overwrites the set `s1` with the result. If needed, `s1`
will be expanded to the size of `s2`.
"""
function intersect!(s1::IntSet32, s2::IntSet32)
    _matched_map!(&, s1.bits, s2.bits)
    s1
end

setdiff(s::IntSet32, ns) = setdiff!(copy(s), ns)
setdiff!(s::IntSet32, ns) = (for n in ns; _delete!(s, n); end; s)
function setdiff!(s1::IntSet32, s2::IntSet32)
    _matched_map!(>, s1.bits, s2.bits)
    s1
end

symdiff(s::IntSet32, ns) = symdiff!(copy(s), ns)
"""
    symdiff!(s, itr)
For each element in `itr`, destructively toggle its inclusion in set `s`.
"""
symdiff!(s::IntSet32, ns) = (for n in ns; symdiff!(s, n); end; s)
"""
    symdiff!(s, n)
The set `s` is destructively modified to toggle the inclusion of integer `n`.
"""
function symdiff!(s::IntSet32, n::Integer)
    0 <= n < typemax(Int) || _throw_intset32_bounds_err()
    val = !(n in s)
    _setint!(s, n, val)
    s
end
function symdiff!(s1::IntSet32, s2::IntSet32)
    _matched_map!(xor, s1.bits, s2.bits)
    s1
end

@inline function in(n::Integer, s::IntSet32)
    if 1 <= n <= length(s.bits)
        @inbounds b = s.bits[n]
    else
        b = false
    end
    b
end

# Use the next-set index as the state to prevent looking it up again in done
start(s::IntSet32) = next(s, 0)[2]
function next(s::IntSet32, i)
    nextidx = i == typemax(Int) ? 0 : findnext(s.bits, i+1)
    (i, nextidx)
end
done(s::IntSet32, i) = i <= 0


@noinline _throw_intset32_notempty_error() = throw(ArgumentError("collection must be non-empty"))
function last(s::IntSet32)
    idx = findprev(s.bits, length(s.bits))
    idx == 0 ? _throw_intset32_notempty_error() : idx
end

length(s::IntSet32) = sum(s.bits)

function show(io::IO, s::IntSet32)
    print(io, "IntSet32([")
    first = true
    for n in s
        !first && print(io, ", ")
        print(io, n)
        first = false
    end
    print(io, "])")
end

function ==(s1::IntSet32, s2::IntSet32)
    l1 = length(s1.bits)
    l2 = length(s2.bits)
    # If the lengths are the same, simply punt to bitarray comparison
    l1 == l2 && return s1.bits == s2.bits

    # Swap so s1 is always longer
    if l1 < l2
        s2, s1 = s1, s2
        l2, l1 = l1, l2
    end
    # Iteratively check the chunks of the bitarrays
    c1 = s1.bits.chunks
    c2 = s2.bits.chunks
    @inbounds for i in 1:length(c2)
        c1[i] == c2[i] || return false
    end
    # Ensure remaining chunks are zero
    @inbounds for i in length(c2)+1:length(c1)
        c1[i] == UInt64(0) || return false
    end
    return true
end

issubset(a::IntSet32, b::IntSet32) = isequal(a, intersect(a,b))
<(a::IntSet32, b::IntSet32) = (a<=b) && !isequal(a,b)
<=(a::IntSet32, b::IntSet32) = issubset(a, b)

const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
function hash(s::IntSet32, h::UInt)
    h ⊻= hashis_seed
    bc = s.bits.chunks
    i = length(bc)
    while i > 0 && bc[i] == UInt64(0)
        # Skip trailing empty bytes to prevent extra space from changing the hash
        i -= 1
    end
    while i > 0
        h = hash(bc[i], h)
        i -= 1
    end
    h
end