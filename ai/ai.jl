include("engine.jl")

##############
#AI
##############

#DEBUG
global abN = 0
global gLast=nothing
#END DEBUG

#TODO
#this is the main (recursive loop for the minimax evaluation)
#note: may be implemented partially on the client side in javascript
# type MiniMaxTree
#tree for evaluation
#TODO memoise: make sure states are identical if situation is identical - maybe define custom hash, use IntSets everywhere, and maybe-maybe (doublecheck) leave alpha and beta out of the memoise hash
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
        for card in validMoves(g)
            #create new state
            gNew = newState(g, Card(card))

            # #DEBUG
            # print(g)
            # #END DEBUG

            α = max(α, alfabeta(gNew, depth-1, α, β))
            if β ≤ α
                break                            # (* Beta cut-off *)
            end
        end
        return α
    else
        for card in validMoves(g)
            #create new state
            gNew = newState(g, Card(card))

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
