include("engine.jl")

##############
#AI
##############

#DEBUG
global abN = 0
global gLast=nothing
#END DEBUG

#RNG
SEED = 0
rng = MersenneTwister(SEED)
# rng = RandomDevice() #truly random
moves = Dict{Card, Int64}()

#egymas melletti lapok (pl. tF,tU,t9) eleg az egyiket valasztanunk
#mondjuk a legnagyobbat.
#Kivetel1: zT,zK nem mindegy. Kivetel2: adu 7-es vagy 8-as nem mindegy (ulti-repulonel)

#a legnagyobbat valasztjuk - lehetne a legkisebb vagy random is
pickFromStreak(streak::CardSet32) = length(streak) > 1 ? first(streak) : streak
adu8(g::GameState) = Card(g.contract.suit, _8)
adu7(g::GameState) = Card(g.contract.suit, _7)

extendStreak(result, streak, card) = (result, union(streak, card))
breakStreak(result, streak, card, inV) = (union(result, pickFromStreak(streak)), inV ? card : CardSet32())

#BUG TODO: check 494c2399f96cc0af5508336cab0f7415b5708f44 vs. d51d5d75f51ee3a1ada61c989eccfaa7df8bc0e3 2x time and abN
function removeNeighbours(g::GameState, vm::CardSet32)
    if length(vm) <= 1 return vm end
    
    (result, streak) = (CardSet32(), CardSet32())

    remaining = union(ps(g, p1).hand, ps(g, p2).hand, ps(g, p3).hand)
    assert(vm in remaining)
    # remaining = setdiff(s1, s2)(remaining, vm)
    
    for card in remaining
        #DEBUG show(result); print(" | "); show(streak); print(" | "); show(card);println()
        if card in vm
            if !(card in AT) && hanyAT(streak) > 1 || #tizes es nemtizes
                    !sameSuit(card, streak, suitof(card)) || #mas szin
                    card == adu7(g)  #adu7 tori, mert 1. adu 8-7 - mindketto fontos 2. csendesultinal szamit | Note: 8-as nem, mert ugysem fordul elo, hogy 8-9 teheto

                (result, streak) = breakStreak(result, streak, card, true)
            else
                (result, streak) = extendStreak(result, streak, card)
            end
        else #in remaining
            (result, streak) = breakStreak(result, streak, card, false)
        end
    end
    #DEBUG show(result); print(" | "); show(streak); print(" | ");println()

    (result, streak) = breakStreak(result, streak, CardSet32(), false)  #register last streak
    #DEBUG show(result); print(" | "); show(streak); print(" | ");println()

    return result
end

#     #terrible spaghetti - but a bit faster :(
# function removeNeighbours(g::GameState, vm::CardSet32)
#     #terrible spaghetti - maybe rewrite one day?
#     if length(vm) <= 1 return vm end
    
#     remaining = union(ps(g, p1).hand, ps(g, p2).hand, ps(g, p3).hand)
#     assert(length(remaining) > length(vm))
    
#     streak = CardSet32()
#     result = CardSet32()

#     stateV = start(vm)
#     stateR = start(remaining)
#     (cV, stateV) = next(vm, stateV)
#     (cR, stateR) = next(remaining, stateR)
#     oneMoreRound = 2 #to make sure the last is recorded
#     while !done(vm, stateV) || !done(vm, stateR) || oneMoreRound > 0
#         #DEBUG: show(streak);print(" | "); show(result); print(" | "); show(cV); show(cR); println()
#         if cR == cV
#             #TK boundary, suit boundary, or adu8,7
#             if (cV in K && !isempty(streak)) || !sameSuit(cV, streak, suitof(cV)) || (cV == adu7(g) && adu8(g) in streak)
#                 result = union(result, pickFromStreak(streak)) #a legnagyobbat valasztjuk - lehetne a legkisebb vagy random is
#                 streak = cV
#             end
#             streak = union(streak, cV) #continue streak
            
#             #move both
#             if !done(vm, stateV)
#                 (cV, stateV) = next(vm, stateV)
#             end
#             if !done(vm, stateR)
#                 (cR, stateR) = next(remaining, stateR)
#             end
#         else
#             if !isempty(streak)
#                 result = union(result, pickFromStreak(streak)) #a legnagyobbat valasztjuk - lehetne a legkisebb vagy random is
#                 streak = CardSet32()
#             end
#             if !done(vm, stateR)
#                 (cR, stateR) = next(remaining, stateR)
#             end
#         end

#         if done(vm, stateV)
#             oneMoreRound -= 1
#         end
#     end

#     if !isempty(streak)
#         result = union(result, pickFromStreak(streak))
#     end

#     return result
# end

#heuristics of ordering the right moves
#TODO smallestCards
function sortMoves(g::GameState, vm::CardSet32)
    if length(vm) <= 1 return vm end
    valid = vm
        
    result = Vector{Card}() #ordered

    #sort suit by length
    shorterThan(x,y) = length(valid * x)>length(valid * y)
    suitsInvalid = filter(x->!isempty(valid * x), [t,z,m,p]) #TODO: randomize maybe later?
    suitsInLengthOrder = sort(suitsInvalid, lt=shorterThan)

    function largestCardsInsuitLengthOrder(result, valid, what=:largest)
        for suit in suitsInLengthOrder
            if isempty(valid * suit)
                continue
            end

            if what == :largest
                cards = largestCard(valid * suit, suit)
                push!(result, cards)
            elseif what == :smallest
                cards = last(valid * suit) #TODO: properly for betli/duri
                push!(result, cards)
            else #:all
                cards = valid * suit
                append!(result, toArray(cards))
            end
            valid -= cards
        end
        #show(result); print(" | "); show(valid); println() #DEBUG
        return (result, valid)
    end

    smallestCardsInsuitLengthOrder(result, valid) = largestCardsInsuitLengthOrder(result, valid, :smallest)

    allCardsInsuitLengthOrder(result, valid) = largestCardsInsuitLengthOrder(result, valid, :all)

    if g.contract.suit <= p #adu jatek
        if isempty(g.asztal) #elso helyrol
            #largest cards in suit length order
            (result, valid) = largestCardsInsuitLengthOrder(result, valid)
            #smallest cards in suit length order
            (result, valid) = smallestCardsInsuitLengthOrder(result, valid)
            #the rest in suit length order
            (result, valid) = allCardsInsuitLengthOrder(result, valid)
        else # masodik vagy harmadik helyrol - legkisebb dobas vagy felulutes
            #smallest card in suit length order
            (result, valid) = smallestCardsInsuitLengthOrder(result, valid)
            #then largest card in suit length order
            (result, valid) = largestCardsInsuitLengthOrder(result, valid)
            #the rest in suit length order
            (result, valid) = allCardsInsuitLengthOrder(result, valid)
        end
    else #TODO szintelen jatek, foleg betli

    end

    if !isempty(valid) push!(result, toArray(valid)) end

    # show(result); print(" | "); show(valid); println() #DEBUG
    assert(length(vm) == length(result)) #make sure we have all cards sorted
    return result
end

#heuristics of picking the right moves
function pickMoves(g::GameState, vm::CardSet32, depth::Int, α::Int, β::Int)
    vm = removeNeighbours(g, vm)

    vm = sortMoves(g, vm)
    return vm
end

#TODO
#this is the main (recursive loop for the minimax evaluation)
#note: may be implemented partially on the client side in javascript
# type MiniMaxTree
#tree for evaluation
#TODO memoise: make sure states are identical if situation is identical - maybe define custom hash, use IntSets everywhere, and maybe-maybe (doublecheck) leave alpha and beta out of the memoise hash
#BUG players are not in turn. Make sure max-min players are called right (if maximisingPlayer ...). Eventually there will be three types of players with different score goals (csendes ulti miatt)
#TODO: memoize better?
# @memoize Dict 
function alfabeta(g::GameState, depth::Int, α::Int, β::Int)
    #DEBUG
    global abN += 1
    # global gLast = g
    # info(depth, " ", α, " ", β)
    #END DEBUG
    if  depth == 0 || isempty(ps(g, g.currentPlayer).hand)
        return score(g)
    end
    if  g.currentPlayer == p1
        for card in pickMoves(g, validMoves(g), depth, α, β)
            #create new state
            gNew = newState(g, card)

            α = max(α, alfabeta(gNew, depth-1, α, β))

            # #DEBUG
            if depth > -2
                moves[card] = α
            end
            # #END DEBUG

            if β ≤ α
                break                            # (* Beta cut-off *)
            end
        end
        return α
    else
        for card in pickMoves(g, validMoves(g), depth, α, β)
            #create new state
            gNew = newState(g, card)

            # #DEBUG
            # print(g)
            # #END DEBUG

            β = min(β, alfabeta(gNew, depth-1, α, β))
            if β ≤ α
                break                             # (* Alpha cut-off *)
            end
        end
        return β
    end
end
# Notes:
#
# -'for each child of node' - Rather than editing the state of the current board, create an entirely new board that is the result of applying the move. By using immutable objects, your code will be less prone to bugs and quicker to reason about in general.
#
# -To use this method, call it for every possible move you can make from the current state, giving it depth -1, -Infinity for alpha and +Infinity for beta, and it should start by being the non-moving player's turn in each of these calls - the one that returns the highest value is the best one to take.
#
# It's very very conceptually simple. If you code it right then you never instantiate more than (depth) boards at once, you never consider pointless branches and so on.

#generate (sub)hands from the current state, and run
#Monte Carlo simulation on it
#use existing probabilities for hand distribution
#and hypergeometric probabilities otherwise
function MonteCarlo()
end

##############
#Tests
##############
