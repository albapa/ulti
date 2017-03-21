# This file was a part of Julia. License is MIT: http://julialang.org/license

import Base: similar, copy, copy!, eltype, push!, pop!, delete!, shift!,
             empty!, isempty, union, union!, intersect, intersect!,
             setdiff, setdiff!, symdiff, symdiff!, in, start, next, done,
             last, length, show, hash, issubset, ==, <=, <, unsafe_getindex,
             unsafe_setindex!, findnextnot, first
if !isdefined(Base, :complement)
    export complement, complement!
else
    import Base: complement, complement!
end

immutable CardSet32
    cs::UInt32
end

typealias Card CardSet32 #a card is a card set with one element

CardSet32() = CardSet32(UInt32(0))

function CardSet32(cards::Array{Card, 1})
    cs = UInt32(0)
    for card in cards
        # cs |= 0x00000001 << Int(card)
        cs |= card
    end
    return CardSet32(cs)
end

const emptyCardSet32 = CardSet32()

function <(cs1::Card, cs2::Card)
    cs1.cs < cs2.cs
end

union(cs1::CardSet32, cs2::CardSet32) = CardSet32(cs1.cs | cs2.cs)
union(cs1::CardSet32, css...) = union(cs1, union(css...))

intersect(cs1::CardSet32, cs2::CardSet32) = CardSet32(cs1.cs & cs2.cs)
intersect(cs1::CardSet32, css...) = intersect(cs1, intersect(css...))

in(cs1::CardSet32, cs2::CardSet32) = isequal(cs1.cs, cs1.cs & cs2.cs)

function in(cardIndex::Int64, cs2::CardSet32)
    if 0 <= cardIndex < 32
        return in(CardSet32(0x00000001 << cardIndex), cs2)
    end
    throw(BoundsError("needed: 0 <= card < 32"))
end

length(cs1::CardSet32) = count_ones(cs1.cs)

function toArray(cs1::CardSet32)
    result = Vector{Card}()
    for card in cs1 push!(result, card) end
    return result
end

complement(cs1::CardSet32) = CardSet32(!cs.cs)
setdiff(cs1::CardSet32, cs2::CardSet32) = intersect(cs1, complement(cs2))
symdiff(cs1::CardSet32, cs2::CardSet32) = CardSet32(cs1.cs $ cs2.cs) #xor / flip

#add card(s)
function add(cs1::CardSet32, items::CardSet32)
    if !UNSAFE && !isempty(intersect(items, cs1)) throw(ArgumentError("items already in cs1, cannot remove")) end
    union(cs1, items)
end

#remove card(s)
function remove(cs1::CardSet32, items::CardSet32)
    if !UNSAFE && !in(items, cs1) throw(ArgumentError("items not in cs1, cannot remove")) end
    setdiff(cs1, items)
end

isempty(cs1::CardSet32) = isequal(cs1.cs, UInt32(0))

typealias CardSet32_iterstate Tuple{UInt32, UInt32}
function start(cs1::CardSet32)
    return (cs1.cs, 0x00000001) #state is the set and an index
end

function done(cs1::CardSet32, state::CardSet32_iterstate)
    return isequal(state[1], UInt32(0))
end

function next(cs1::CardSet32, state::CardSet32_iterstate)
    trailzeros = trailing_zeros(state[1])
    nextValue = state[2] << trailzeros
    return (CardSet32(nextValue), (state[1] >>> (trailzeros + 1), nextValue << 1))
end

# show(cs1::CardSet32)
    # showCard
# end


#########
#IntSet
#########







# type IntSet32
#     bits::BitVector
#     inverse::Bool
#     IntSet32() = new(fill!(BitVector(32), false), false)
# end
# IntSet32(itr) = union!(IntSet32(), itr)

# similar(s::IntSet32) = IntSet32()
# copy(s1::IntSet32) = copy!(IntSet32(), s1)
# function copy!(to::IntSet32, from::IntSet32)
#     resize!(to.bits, length(from.bits))
#     copy!(to.bits, from.bits)
#     to.inverse = from.inverse
#     to
# end
# eltype(s::IntSet32) = Int
# sizehint!(s::IntSet32, n::Integer) = (_resize0!(s.bits, n+1); s)

# # only required on 0.3:
# function first(itr::IntSet32)
#     state = start(itr)
#     done(itr, state) && throw(ArgumentError("collection must be non-empty"))
#     next(itr, state)[1]
# end

# # An internal function for setting the inclusion bit for a given integer n >= 0
# @inline function _setint!(s::IntSet32, n::Integer, b::Bool)
#     idx = n+1
#     if idx > length(s.bits)
#         !b && return s # setting a bit to zero outside the set's bits is a no-op
#         newlen = idx + idx>>1 # This operation may overflow; we want saturation
#         _resize0!(s.bits, ifelse(newlen<0, typemax(Int), newlen))
#     end
#     unsafe_setindex!(s.bits, b, idx) # Use @inbounds once available
#     s
# end

# # An internal function to resize a bitarray and ensure the newly allocated
# # elements are zeroed (will become unnecessary if this behavior changes)
# @inline function _resize0!(b::BitVector, newlen::Integer)
#     len = length(b)
#     resize!(b, newlen)
#     len < newlen && unsafe_setindex!(b, false, len+1:newlen) # resize! gives dirty memory
#     b
# end

# # An internal function that resizes a bitarray so it matches the length newlen
# # Returns a bitvector of the removed elements (empty if none were removed)
# function _matchlength!(b::BitArray, newlen::Integer)
#     len = length(b)
#     len > newlen && return splice!(b, newlen+1:len)
#     len < newlen && _resize0!(b, newlen)
#     return BitVector(0)
# end

# const _intset_bounds_err_msg = "elements of IntSet32 must be between 0 and typemax(Int)-1"

# function push!(s::IntSet32, n::Integer)
#     0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
#     _setint!(s, n, !s.inverse)
# end
# push!(s::IntSet32, ns::Integer...) = (for n in ns; push!(s, n); end; s)

# function pop!(s::IntSet32)
#     s.inverse && throw(ArgumentError("cannot pop the last element of complement IntSet32"))
#     pop!(s, last(s))
# end
# function pop!(s::IntSet32, n::Integer)
#     0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
#     n in s ? (_delete!(s, n); n) : throw(KeyError(n))
# end
# function pop!(s::IntSet32, n::Integer, default)
#     0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
#     n in s ? (_delete!(s, n); n) : default
# end
# function pop!(f::Function, s::IntSet32, n::Integer)
#     0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
#     n in s ? (_delete!(s, n); n) : f()
# end
# _delete!(s::IntSet32, n::Integer) = _setint!(s, n, s.inverse)
# delete!(s::IntSet32, n::Integer) = n < 0 ? s : _delete!(s, n)
# shift!(s::IntSet32) = pop!(s, first(s))

# empty!(s::IntSet32) = (fill!(s.bits, false); s.inverse = false; s)
# isempty(s::IntSet32) = s.inverse ? length(s.bits) == typemax(Int) && all(s.bits) : !any(s.bits)

# # Mathematical set functions: union!, intersect!, setdiff!, symdiff!
# # When applied to two intsets, these all have a similar form:
# # - Reshape s1 to match s2, occasionally grabbing the bits that were removed
# # - Use map to apply some bitwise operation across the entire bitvector
# #   - These operations use functors to work on the bitvector chunks, so are
# #     very efficient... but a little untraditional. E.g., (p > q) => (p & ~q)
# # - If needed, append the removed bits back to s1 or invert the array

# union(s::IntSet32, ns) = union!(copy(s), ns)
# union!(s::IntSet32, ns) = (for n in ns; push!(s, n); end; s)
# function union!(s1::IntSet32, s2::IntSet32)
#     l = length(s2.bits)
#     if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = true
#     else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
#     end
#     s1
# end

# intersect(s1::IntSet32) = copy(s1)
# intersect(s1::IntSet32, ss...) = intersect(s1, intersect(ss...))
# function intersect(s1::IntSet32, ns)
#     s = IntSet32()
#     for n in ns
#         n in s1 && push!(s, n)
#     end
#     s
# end
# intersect(s1::IntSet32, s2::IntSet32) = intersect!(copy(s1), s2)
# function intersect!(s1::IntSet32, s2::IntSet32)
#     l = length(s2.bits)
#     if     !s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
#     elseif  s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
#     elseif !s1.inverse &  s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     else #= s1.inverse &  s2.inverse=# e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     end
#     s1
# end

# setdiff(s::IntSet32, ns) = setdiff!(copy(s), ns)
# setdiff!(s::IntSet32, ns) = (for n in ns; _delete!(s, n); end; s)
# function setdiff!(s1::IntSet32, s2::IntSet32)
#     l = length(s2.bits)
#     if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
#     elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
#     else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
#     end
#     s1
# end

# symdiff(s::IntSet32, ns) = symdiff!(copy(s), ns)
# symdiff!(s::IntSet32, ns) = (for n in ns; symdiff!(s, n); end; s)
# function symdiff!(s::IntSet32, n::Integer)
#     0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
#     val = (n in s) ⊻ !s.inverse
#     _setint!(s, n, val)
#     s
# end
# function symdiff!(s1::IntSet32, s2::IntSet32)
#     e = _matchlength!(s1.bits, length(s2.bits))
#     map!(⊻, s1.bits, s1.bits, s2.bits)
#     s2.inverse && (s1.inverse = !s1.inverse)
#     append!(s1.bits, e)
#     s1
# end

# function in(n::Integer, s::IntSet32)
#     idx = n+1
#     if 1 <= idx <= length(s.bits)
#         unsafe_getindex(s.bits, idx) != s.inverse
#     else
#         ifelse((idx <= 0) | (idx > typemax(Int)), false, s.inverse)
#     end
# end

# # Use the next-set index as the state to prevent looking it up again in done
# start(s::IntSet32) = next(s, 0)[2]
# function next(s::IntSet32, i, invert=false)
#     if s.inverse ⊻ invert
#         # i+1 could rollover causing a BoundsError in findnext/findnextnot
#         nextidx = i == typemax(Int) ? 0 : findnextnot(s.bits, i+1)
#         # Extend indices beyond the length of the bits since it is inverted
#         nextidx = nextidx == 0 ? max(i, length(s.bits))+1 : nextidx
#     else
#         nextidx = i == typemax(Int) ? 0 : findnext(s.bits, i+1)
#     end
#     (i-1, nextidx)
# end
# done(s::IntSet32, i) = i <= 0

# # Nextnot iterates through elements *not* in the set
# nextnot(s::IntSet32, i) = next(s, i, true)

# function last(s::IntSet32)
#     l = length(s.bits)
#     if s.inverse
#         idx = l < typemax(Int) ? typemax(Int) : findprevnot(s.bits, l)
#     else
#         idx = findprev(s.bits, l)
#     end
#     idx == 0 ? throw(ArgumentError("collection must be non-empty")) : idx - 1
# end

# length(s::IntSet32) = (n = sum(s.bits); ifelse(s.inverse, typemax(Int) - n, n))

# complement(s::IntSet32) = complement!(copy(s))
# complement!(s::IntSet32) = (s.inverse = !s.inverse; s)

# function show(io::IO, s::IntSet32)
#     print(io, "IntSet32([")
#     first = true
#     for n in s
#         if s.inverse && n > 2 && done(s, nextnot(s, n-3)[2])
#              print(io, ", ..., ", typemax(Int)-1)
#              break
#          end
#         !first && print(io, ", ")
#         print(io, n)
#         first = false
#     end
#     print(io, "])")
# end

# function ==(s1::IntSet32, s2::IntSet32)
#     l1 = length(s1.bits)
#     l2 = length(s2.bits)
#     l1 < l2 && return ==(s2, s1) # Swap so s1 is always equal-length or longer

#     # Try to do this without allocating memory or checking bit-by-bit
#     if s1.inverse == s2.inverse
#         # If the lengths are the same, simply punt to bitarray comparison
#         l1 == l2 && return s1.bits == s2.bits
#         # Otherwise check the last bit. If equal, we only need to check up to l2
#         return findprev(s1.bits, l1) == findprev(s2.bits, l2) &&
#                unsafe_getindex(s1.bits, 1:l2) == s2.bits
#     else
#         # one complement, one not. Could feasibly be true on 32 bit machines
#         # Only if all non-overlapping bits are set and overlaps are inverted
#         return l1 == typemax(Int) &&
#                map!(!, unsafe_getindex(s1.bits, 1:l2)) == s2.bits &&
#                (l1 == l2 || all(unsafe_getindex(s1.bits, l2+1:l1)))
#     end
# end

# const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
# function hash(s::IntSet32, h::UInt)
#     # Only hash the bits array up to the last-set bit to prevent extra empty
#     # bits from changing the hash result
#     l = findprev(s.bits, length(s.bits))
#     hash(unsafe_getindex(s.bits, 1:l), h) ⊻ hash(s.inverse) ⊻ hashis_seed
# end

# issubset(a::IntSet32, b::IntSet32) = isequal(a, intersect(a,b))
# <(a::IntSet32, b::IntSet32) = (a<=b) && !isequal(a,b)
# <=(a::IntSet32, b::IntSet32) = issubset(a, b)