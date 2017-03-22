# This file was a part of Julia. License is MIT: http://julialang.org/license

import Base: AbstractSet, similar, copy, copy!, eltype, push!, pop!, delete!, shift!,
             empty!, isempty, union, union!, intersect, intersect!,
             setdiff, setdiff!, symdiff, symdiff!, in, start, next, done,
             last, length, show, hash, issubset, ==, <=, <, unsafe_getindex,
             unsafe_setindex!, findnextnot, first
if !isdefined(Base, :complement)
    export complement, complement!
else
    import Base: complement, complement!
end

immutable CardSet32 <: AbstractSet
    cs::UInt32
end

typealias Card CardSet32 #a card is a card set with one element

CardSet32() = CardSet32(UInt32(0))

function CardSet32(cards::Array{Card, 1})
    result = CardSet32()
    for card in cards
        result = union(result, card)
    end
    return result
end

const emptyCardSet32 = CardSet32()

function <(cs1::Card, cs2::Card)
    cs1.cs < cs2.cs
end

eltype(cs1::CardSet32) = UInt32

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

complement(cs1::CardSet32) = CardSet32(~cs1.cs)
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
    return (cs1.cs, 0x80000000) #state is the set and an index
end

function done(cs1::CardSet32, state::CardSet32_iterstate)
    return isequal(state[1], UInt32(0))
end

function next(cs1::CardSet32, state::CardSet32_iterstate)
    leadzeros = leading_zeros(state[1])
    nextValue = state[2] >>> leadzeros
    return (CardSet32(nextValue), (state[1] << (leadzeros + 1), nextValue >>> 1))
end

function first(cs1::CardSet32)
    isempty(cs1) && throw(ArgumentError("collection must be non-empty"))
    CardSet32(0x80000000 >>> leading_zeros(cs1.cs))
end

function last(cs1::CardSet32)
    isempty(cs1) && throw(ArgumentError("collection must be non-empty"))
    CardSet32(0x00000001 << trailing_zeros(cs1.cs))
end