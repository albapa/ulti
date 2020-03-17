# This file was a part of Julia. License is MIT: http://julialang.org/license

import Base: AbstractSet, similar, copy, copy!, eltype, push!, pop!, delete!,
             empty!, isempty, union, union!, intersect, intersect!,
             setdiff, setdiff!, symdiff, symdiff!, in, iterate,
             last, length, show, display, hash, issubset, ==, <=, <, +, *, -, !, unsafe_getindex,
             unsafe_setindex!, findnextnot, first, getindex, rand, xor
using Random

if !isdefined(Base, :complement)
    export complement, complement!
else
    import Base: complement, complement!
end

struct CardSet32 <: AbstractSet{UInt32}
    cs::UInt32
end

#IDEA offset as type parameter -> CardSet32{:offset}, CardSet32{:5} -> get it with eltype

const Card = CardSet32 #a card is a card set with one element

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
eltype(::Type{CardSet32}) = UInt32

union(cs1::CardSet32, cs2::CardSet32) = CardSet32(cs1.cs | cs2.cs)
union(cs1::CardSet32, css...) = union(cs1, union(css...))
+(cs1::CardSet32, cs2::CardSet32) = union(cs1, cs2)

intersect(cs1::CardSet32, cs2::CardSet32) = CardSet32(cs1.cs & cs2.cs)
intersect(cs1::CardSet32, css...) = intersect(cs1, intersect(css...))
*(cs1::CardSet32, cs2::CardSet32) = intersect(cs1, cs2)

in(cs1::CardSet32, cs2::CardSet32) = isequal(cs1.cs, cs1.cs & cs2.cs)
hash(cs1::CardSet32) = cs1.cs

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
!(cs1::CardSet32) = complement(cs1)

setdiff(cs1::CardSet32, cs2::CardSet32) = intersect(cs1, complement(cs2))
-(cs1::CardSet32, cs2::CardSet32) = setdiff(cs1, cs2)

symdiff(cs1::CardSet32, cs2::CardSet32) = CardSet32(xor(cs1.cs, cs2.cs)) #xor / flip
xor(cs1::CardSet32, cs2::CardSet32) = symdiff(cs1, cs2)


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

const CardSet32_iterstate = Tuple{UInt32, UInt32}

function iterate(cs1::CardSet32)
    return iterate(cs1, (cs1.cs, 0x80000000)) #state is the set and an index
end

function iterate(cs1::CardSet32, state::CardSet32_iterstate)
    isequal(state[1], UInt32(0)) && return nothing
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

function getindex(cs1::CardSet32, index::Int)
    if  index <= 0 || index > length(cs1) throw(BoundsError("index out of bounds")) end
    state = start(cs1)
    val = CardSet32()
    for i in 1:index
        (val, state) = next(cs1, state)
    end
    return val
end

#pick a random card
function rand(rng::AbstractRNG, cs1::CardSet32)
    cs1[rand(rng, 1:length(cs1))]
    # rand(rng, toArray(cs1)) #TODO more efficiency: make set indexible by getindex
end