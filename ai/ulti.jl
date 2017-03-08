
##############
#Game Engine
##############

#TODO 1: UX
    #- User enters game state, or chooses a pre-defined one (with a number), or a random pre-defined one ('random')
      #hands are evaluated using eval(parse("..."))
    #- GameState.show emits hands, discard piles, table, contract, etc.
    #- User can input
        #a) card to play (e.g. zt)
        #b) enter for ai to move, n2 for 2 ai moves (so he can control one player),
            #run for full ai mode
        #c) move to trick (goto 0 or restart, goto 2 second trick, goto -1 or 'p' previous trick)
    #At the game end the ai scores the round
    #+1: Az ai kiirja a varhato legrosszabb minimax erteket

#TODO 2: terites - az ai terit, ha minden agon ugyanaz az eredmeny (lejatszastol fuggetlenul)

#IDEA 3: for pruning we can pick key cards,
    #distribute them based on hypergeometric and/or based on existing information
    #and generate hands. Also merge branches with irrelevant differences (drop z9 vs. drop zl)

#a set of cards
#implemented as a memoised set of sets to avoid duplication
#Note: could be implemented as a full-blown class if needed
typealias CardSet IntSet

#Players
typealias Player Int
const p1 = Player(1)
const p2 = Player(2)
const p3 = Player(3)
const p4 = Player(4)
const p5 = Player(5)
const p6 = Player(6)
playerNames = Dict([(1, "Alfa "), (2, "Béta "), (3, "Gamma"), (4, "Delta"), (5, "Epszi"), (6, "Théta"), ])

type PlayerState
    player::Player
    hand::CardSet
    discard::Array{Card}
end

type GameState
    contract::Contract  #mi a bemondas

    deck::CardSet       # leosztatlan pakli
    table::Array{Card}  # asztal kozepe - here order matters (pl. 🌰K-ra adu 🎃9 nem ugyanaz mint adu 🎃9-re 🌰K dobas: az egyikre adut kell tenni, a masikra makkot ha van) thus it is not a set
    talon::CardSet      # talon

    playerStates::Array{PlayerState}

    currentPlayer::Player

    #default constructor
    function GameState(contract::Contract, deck::CardSet, table::Array{Card,1}, talon::CardSet, playerStates::Array{PlayerState,1}, currentPlayer::Player)
      new(contract, deck, table, talon, playerStates, currentPlayer)
    end

    #parser
    function GameState(s::String)
      #example: ('piros nsz ulti', 't7 t8 p9 pa pf ps pk', 'z8 z9', ... <<<all 8 sets>>>)
      #idea: allow for generic cards and suits, such as zx (any zold) or xx (any card) and deal them randomly
      #checks: are all cards accounted for?
      #nobody has the right number of cards

    end

    #efficiend storage for game state:
    #list of 32 cardsets, 3 bits each -> 96 bits + bemondas a #tablazatbol
    # function compact()
    # function decompact()
end

#Move a card
#Note: special for table which is an array not a set (order matters)?
function move!(g::GameState, card::Card, from, to)
  pop!(from, card)
  push!(to, card)
end

#this is the main (recursive loop for the minimax evaluation)
#note: may be implemented partially on the client side in javascript
function score(g::GameState)

    #if all cards are played ...
end

function showCard(card::Card, io::IO=STDOUT)
  print(io, cards[card], " ")
end

function showCard(cardCollection, io::IO=STDOUT)
    if isempty(cards) return end
    toPrint = sort([card for card in cardCollection]) #print in order
    for card in toPrint
        showCard(card, io)    
    end
end

function show(io::IO, pstate::Array{PlayerState})
    for pl in pstate
        print(io, playerNames[pl.player]); print(io, ": ")
        showCard(pl.hand)
        println(io); println(io)
    end
    println(io); println(io)
    for pl in pstate
        print(io, playerNames[pl.player]); print(io, " ütései: ")
        showCard(pl.discard)
        println(io)
    end
end


function show(io::IO, g::GameState)
    println(io, g.contract); println(io)
    print(io, "Asztal: "); showCard(g.table, io); println(io); println(io); println(io)
    show(io, g.playerStates)
    print(io, "Talon: " ); showCard(g.talon, io); println(io)
end

#The valid card to play in this trick (if there is already a card on the table)
function trickable(hand::CardSet, table::CardSet, suit::Suit)
    sameSuitLarger::CardSet()
    sameSuiteSmaller::CardSet()
    trump::CardSet()
    other::CardSet()

    for card in hand

    end
end

#TODO
#The valid moves in that round
# function legalMoves(g::GameState)
#     if isempty(g.table) #new trick
#         if isempty(<<<currentPlayer's hand>>>) #gameEnd
#             return CardSet() #no legal moves
#         else
#             legalSet = pCurrent_hand <<<vagy aki jon>>>
#             if(<<<ulti v repulo nem bukhat direkt>>>)
#                 setdiff!(legalSet, <<<adu 7 v. 8>>>)
#         end
#     else #mar van lap
#         playerSets = trickable(pCurrent_hand, g.asztal)
#     end
# end

##############
#AI
##############

#TODO
# type MiniMaxTree
#tree for evaluation

#generate (sub)hands from the current state, and run
#Monte Carlo simulation on it
#use existing probabilities for hand distribution
#and hypergeometric probabilities otherwise
function MonteCarlo()
end

##############
#Engine runtime loop
##############
g = GameState(
  Contract(p, [ContractElement(_4x, parti, [], 24)], 24), #elolrol piros passz
  CardSet(), #pakli ures (kiosztva)
  Array{Card, 1}(), #asztal ures
  CardSet([t9, tv]), #talon
  [
    PlayerState(
      Player(1),
      CardSet([pa,pt,pk,pf, mk,mv,m8 ]), #felvevo lapja
      [], #nincs meg utese
    ),
    PlayerState(
      Player(2),
      CardSet([pv,p9, ma, mt, m7]), #2. jatekos lapja
      [], #nincs meg utese
    ),
    PlayerState(
      Player(3),
      CardSet([p8,p7, m9,mf]), #3. jatekos lapja
      [], #nincs meg utese
    )
  ],
  p1 #current player
)

##############
#Tests
##############
