
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

include("basics.jl")

#a set of cards
#implemented as a memoised set of sets to avoid duplication
#Note: could be implemented as a full-blown class if needed
typealias CardSet IntSet
CardSet(cards::Array{Card, 1}) = IntSet([Int(card) for card in cards])

const tizesek = CardSet([tT, zT, mT, pT])
const aszok = CardSet([tA, zA, mA, pA])
const AT = union(tizesek, aszok)
const szinek = Dict(
  t => CardSet([t7,t8,t9,tU,tF,tK,tT,tA]),
  z => CardSet([z7,z8,z9,zU,zF,zK,zT,zA]),
  m => CardSet([m7,m8,m9,mU,mF,mK,mT,mA]),
  p => CardSet([p7,p8,p9,pU,pF,pK,pT,pA]),
)
hanyAsz(cs::CardSet) = length(intersect(cs, aszok))
hanyTizeshanyTizes(cs::CardSet) = length(intersect(cs, tizesek))
hanyAT(cs::CardSet) = length(intersect(cs, AT))
sameSuit(cs::CardSet, suit::Suit) = intersect(cs, szinek[suit])
function sameSuitLarger(cs::CardSet, suit::Suit, card::Card)
#TODO - supporting structure?
end
aduk(cs::CardSet, adu::Suit) = intersect(cs, szinek[adu])

#Players
@enum Player p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 pX=7
const playerNames = Dict([
    (p1, "Alfa "),
    (p2, "Béla "),
    (p3, "Gamma"),
    (p4, "Delta"),
    (p5, "Epszi"),
    (p6, "Tétova"),
    (pX, ""), ]) #barmelyik jatekos (null)

nextPlayer(p::Player) = Player(Int(p) % 3 + 1)
# const FELVEVO = p1
# const ELLENVONAL = [p2, p3]
# const ELLENFEL1 = p2
# const ELLENFEL2 = p3

type PlayerState
    player::Player
    hand::CardSet
    discard::Array{Card, 1}
    negyven::Int #0 vagy 1
    husz::Int #0-3
end

#The game state
#IMPORTANT: as it is copied with shallow copy
#   any field that changes across moves must not be referenced
#   or should be explicitly deep copied by the copy constructor
type GameState
    contract::Contract  #mi a bemondas

    deck::CardSet       # leosztatlan pakli
    table::Array{Card}  # asztal kozepe - here order matters (pl. 🌰K-ra adu 🎃9 nem ugyanaz mint adu 🎃9-re 🌰K dobas: az egyikre adut kell tenni, a masikra makkot ha van) thus it is not a set
    talon::CardSet      # talon

    playerStates::Array{PlayerState}

    currentPlayer::Player
    currentSuit::Suit
    lastTrick::Player       #utolso utes
    lastTrick7::Player      #utolso utes adu hetessel
    butLastTrick8::Player   #utolso elotti utes adu 8-assal
    lastTrickFogottUlti::Player #elbukta a (csendes) ultit
    tricks::Int             #number of tricks
    felvevoTricks::Int      #number of tricks
    ellenvonalTricks::Int   #number of tricks
    felvevoTizesek::Int     #tizesek + aszok + utolso utes
    ellenvonalTizesek::Int  #tizesek + aszok + utolso utes
    felvevoOsszes::Int      #tizesek + aszok + utolso utes + 20 + 40
    ellenvonalOsszes::Int   #tizesek + aszok + utolso utes + 20 + 40

    #Functions?
    #Aszok es tizesek (for 4A, 4T es Parti)
    # p1_A::Int = 0
    # p1_T::Int = 0
    # p23_A::Int = 0
    # p23_T::Int = 0

    #default constructor
    function GameState(contract::Contract, deck::CardSet, table::Array{Card,1},
        talon::CardSet, playerStates::Array{PlayerState,1}, currentPlayer::Player=p1,
        currentSuit::Suit=undecided, lastTrick::Player = pX , lastTrick7::Player = pX,
        butLastTrick8::Player = pX , lastTrickFogottUlti::Player=pX,
        tricks::Int = 0, felvevoTricks = 0, ellenvonalTricks = 0,
        felvevoTizesek::Int=0, ellenvonalTizesek::Int=0, felvevoOsszes::Int=0, ellenvonalOsszes::Int=0)

      new(contract, deck, table, talon, playerStates, currentPlayer, currentSuit, lastTrick, lastTrick7, butLastTrick8, lastTrickFogottUlti, tricks, felvevoTricks, ellenvonalTricks, felvevoTizesek, ellenvonalTizesek, felvevoOsszes, ellenvonalOsszes)
    end

    #parser
    function GameState(bemondas::String, lapok::String)
      #example: ('piros nsz ulti', 't7 t8 p9 pa pf ps pk', 'z8 z9', ... <<<all 8 sets>>>)
      #idea: allow for generic cards and suits, such as zx (any zold) or xx (any card) and deal them randomly
      #checks: are all cards accounted for?
      #nobody has the right number of cards



    end

    #create from serialised value
    function GameState(s::String)

    end

    #efficiend storage for game state:
    #list of 32 cardsets, 3 bits each -> 96 bits + bemondas a #tablazatbol
    # function compact()
    # function decompact()
end

#TODO
# #create signature
# function serialize(stream, g::GameState)
# end

#parse a list of cards
#Format: known cards (e.g. p9) are marked suit (non-capital t,z,m,p) and face (capital 7,8,9,U,F,K,A)
#Special suits: x: any suit, tz: tok vagy zold, pmz: piros vagy makk vagy zold
#Special faces: X:any face Y:'nem fontos' [9UFK] .:'kicsi' [789UFK], explicit: pl. [AT] az asz v tizes
#Examples: "pATYY mAKX z.. tK[U987][U987]":
#Tricky case: a kicsi t tokot, a nagy T Tizest jelol a felreertesek elkerulese vegett
#Alternativ jelolesek:  also: UVJ, tizes: T vagy 10, tok: t vagy o
#Players are separated by '|' or '/'
#Contract and cards are separated by ';'
function parseCards(s::String)
    ###doing prefix parsing
    collections = split(s, ['|', '/'])
    for collection in collections
        for c in collection
            suit = undecided
                if suit == undecided #look for first suit
                    #TODO
                end
        end
    end
    cards = Array{Array{Card, 1}, 1}()
    #parse suits, parse faces

    #deal fix cards, then coloured cards (px), then multicouloured cards (pz.) then the rest (xx, xA)
end

#Move a card
#Note: special for table which is an array not a set (order matters)?
#TODO fix
function move!(card::Card, from, to)
  pop!(from, Int(card)) #deleteat!?
  push!(to, Int(card))
end

function move!(cards::Vector{Card}, from, to)
  #TODO remove old elements from Array | or for card in cards move!(card, from, to)
  append!(cards, from, to)
end

#Evaluate the score based on the game state
#if the game is over, it returns the final score
#otherwise the sum of contracts that have been decided
#undecided contracts yield 0
#TODO instead of Int, return (10,-5,-5) for proper handling of csendesUlti and csendesDuri
function score(g::GameState, ce::ContractElement)
    if ce.bem == parti
        if  g.felvevoOsszes >=100 && g.felvevoTizesek > 0 #ha szaz van nyertunk de egy tizes mindig kell
            return 2 * ce.val #szazzal van meg
        end
        if g.ellenvonalOsszes >=100 && g.ellenvonalTizesek > 0
            return -2 * ce.val #szazzal bukott
        end
        if g.tricks == 10 #vege a jateknak
            assert(g.felvevoTizesek + g.ellenvonalTizesek == 90)
            if g.felvevoOsszes > g.ellenvonalOsszes
                return ce.val
            else
                return -ce.val
            end
        end
        kiadoUtesek = 90 - (g.felvevoTizesek + g.ellenvonalTizesek)
        if g.felvevoOsszes - g.ellenvonalOsszes > kiadoUtesek
            return ce.val #mar barhogyan megnyertuk, akkor is ha a kiado utesek az ellenhez kerulnek
        end
        if g.ellenvonalOsszes - g.felvevoOsszes > kiadoUtesek
            return -ce.val #mar barhogyan megnyertek, akkor is ha a kiado utesek hozzam kerulnek
        end
        return 0

    elseif ce.bem == ulti
        if g.lastTrick7 == p1 return ce.val end #megvan
        if g.tricks == 10 #bukott
            if ce.modosito == elolrol return -ce.val end #elolrol szimplan bukik
            if isempty(ce.kon) return -2 * ce.val end #hatulrol duplan bukik #TODO kiveve ha nem volt ott a hetes
            return -3 * div(ce.val, 2) #hatulrol kotraval triplan bukik, rekontraval 6x, stb.
        end
        return 0    #meg nem tudjuk

    elseif ce.bem == repulo
    #     if g.butLastTrick8 == p1 return ce.val end #megvan
    #     if g.tricks >= 9 return -ce.val #bukott
    #     return 0    #meg nem tudjuk

    elseif ce.bem == negyvenSzaz
        if g.felvevoTizesek >= 60 && g.playerStates[1].negyven > 0 #megvan a szaz
            return ce.val
        end
        if g.ellenvonalTizesek >= 40 || g.playerStates[1].negyven == 0 #bukott vagy sose volt
            return -ce.val
        end
        return 0

    elseif ce.bem == huszSzaz
        if g.felvevoTizesek >= 80 && g.playerStates[1].husz > 0 #megvan a szaz
            return ce.val
        end
        if g.ellenvonalTizesek >= 20 || g.playerStates[1].husz == 0 #bukott vagy sose volt
            return -ce.val
        end
        return 0

    elseif ce.bem == negyAsz
        if length(intersect(g.playerStates[1].discard, aszok)) == 4 #negy aszt vitt
            return ce.val
        end
        ellenvonalUtesek = union(g.playerStates[2].discard, g.playerStates[3].discard, g.talon)
        if length(intersect(ellenvonalUtesek, aszok)) > 0 #legalabb egy asz az ellenvonal utesei kozott
            return -ce.val
        end
        return 0

    elseif ce.bem == negyTizes
        if length(intersect(g.playerStates[1].discard, tizesek)) == 4 #negy tizest vitt
            return ce.val
        end
        ellenvonalUtesek = union(g.playerStates[2].discard, g.playerStates[3].discard, g.talon)
        if length(intersect(ellenvonalUtesek, tizesek)) > 0 #legalabb egy tizes az ellenvonal utesei kozott
            return -ce.val
        end
        return 0

    elseif ce.bem == durchmars || ce.bem == redurchmars
        if length(g.playerStates[2].discard) + length(g.playerStates[3].discard) > 0
            return -ce.val #ellenvonal utes -> bukott
        end
        if g.tricks == 10 #megvan
            assert(length(g.playerStates[1].discard) == 30) #TODO: FELVEVO maybe or count both tricks
            return ce.val #megvan
        end
        return 0    #meg nem tudjuk

    elseif ce.bem == betli || ce.bem == rebetli
        if length(g.playerStates[1].discard) > 0
            return -ce.val #felvevo utes -> bukott
        end
        if g.tricks == 10 #megvan
            assert(length(g.playerStates[2].discard) + length(g.playerStates[3].discard) == 30)
            return ce.val #megvan
        end
        return 0    #meg nem tudjuk

    elseif ce.bem == csendesUlti
        if g.lastTrick7 == p1 return ce.val end #megvan
        if g.lastTrick7 == p2 return -div(ce.val, 2) end #csak 1 jatekosnak fizetem, ezert a fele
        #TODO: WRONG! fix for p2, p3 to optimize their play
        if g.lastTrick7 == p3 return -div(ce.val, 2) end

        if g.lastTrickFogottUlti #bukott #TODO - new state for that
            return -2 * ce.val #hatulrol duplan bukik
        end
        return 0    #meg nem tudjuk vagy nincs

    elseif ce.bem == csendesDuri
        if g.tricks == 10
            if length(g.playerStates[1].discard) == 30 #megvan
                return ce.val
            end #megvan
            if length(g.playerStates[1].discard) == 27 && g.lastTrick != p1
                return -ce.val #bukott, ha csak az utolso utest bukja #TODO fogott ellenvonal duri
            end
        end
        return 0    #meg nem tudjuk vagy nincs
    else
        #TODO: raise exception here
    end
end


#Evaluate the score based on the game state
function score(g::GameState)
    totalScore = 0
    for contractElement in g.contract.contracts
        totalScore += score(g, contractElement)
    end
    return totalScore
end
##############
#UX/UI
##############

function flushScreen()
    println("\n"^100)
end

function showCard(card::Card, io::IO=STDOUT)
  print(io, deck[card], " ")
end

function showCard(cardCollection, io::IO=STDOUT, shortForm=false)
    if isempty(cardCollection) return end
    #TODO fix types
    toPrint = sort([Card(card) for card in cardCollection]) #print in order
    for card in toPrint
        showCard(card, io)
    end
end

function show(io::IO, pstate::Array{PlayerState, 1})
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

function updateState(g::GameState, card::Card)
  gNew = copy(g) #TODO make sure consistency - maybe deep copy for immutability?
  move!(card, gNew.currentPlayer.hand, gNew.asztal)

  if length(gNew.asztal) == 1 #uj szin
      gNew.currentSuit = SuitFace(card)[1]
  if length(gNew.asztal) == 3 #kor vege
        tizasz = length(intersect(g.asztal, union(aszok, tizesek))))
        bestCard = largestCard(gNew.asztal)
        if bestCard == 3
            whoseTrick = currentPlayer
        elseif bestCard == 1
            whoseTrick = nextPlayer(currentPlayer)
        else bestCard == 2
            whoseTrick = nextPlayer(nextPlayer(currentPlayer)))
        end

        #update variables
        gNew.tricks += 1
        if tricks == 10
            lastTrick = whoseTrick
            if gNew.contract.suit <= p
                trump7 = SuitFace(gNew.contract.suit, _7)
                if trump7 == bestCard
                    gNew.lastTrick7 = whoseTrick
                else
                    holaHetes = findfirst(gNew.asztal, trump7)
                    if holaHetes == 3 gNew.lastTrickFogottUlti = currentPlayer
                    elseif holaHetes == 1 gNew.lastTrickFogottUlti = nextPlayer(currentPlayer)
                    elseif holaHetes == 2 gNew.lastTrickFogottUlti = nextPlayer(nextPlayer(currentPlayer))
                    end
                end
            end
        end

        #repulo
        if tricks == 9 && gNew.contract.suit <= p
                trump8 = SuitFace(gNew.contract.suit, _8)
                if trump8 == bestCard
                    gNew.butLastTrick8 = whoseTrick
                end
            end
        end

        if gNew.currentPlayer == p1
            gNew.felvevoTricks += 1
            gNew.felvevoTizesek += tizasz * 10
            gNew.felvevoOsszes+= tizasz * 10
        else
            gNew.ellenvonalTricks += 1
            gNew.ellenvonalTizesek += tizasz * 10
            gNew.ellenvonalOsszes+= tizasz * 10
        end

        move!(gNew.asztal, gNew.playerStates[whoseTrick].discard)

  end

  gNew.currentPlayer == nextPlayer(gNew.currentPlayer)

  return gNew
end

#TODO
#this is the main (recursive loop for the minimax evaluation)
#note: may be implemented partially on the client side in javascript
# type MiniMaxTree
#tree for evaluation
#TODO memoise: make sure states are identical if situation is identical - maybe define custom hash, use IntSets everywhere, and maybe-maybe (doublecheck) leave alpha and beta out of the memoise hash
function alfabeta(g::GameState, depth, α, β)
    if  depth == 0 || isempty(g.playerStates.hand)
         return score(g)
    end
    if  g.currentPlayer == p1
        for card in ValidMoves(g)
            #create new state
            gNew = updateState(g, card)
            α = max(α, alfabeta(gNew, depth-1, α, β))
            if β ≤ α
                break                            # (* Beta cut-off *)
            end
        return α
      end
    else
        for card in ValidMoves(g)
            #create new state
            gNew = updateState(g, card)
            β = min(β, alfabeta(gNew, depth-1, α, β))
            if β ≤ α
                break                             # (* Alpha cut-off *)
            end
        return β
      end
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
#Engine runtime loop
##############
g = GameState(
  Contract(p, [ContractElement(elolrol, parti, [], 24)], 24), #elolrol piros passz
  CardSet(), #pakli ures (kiosztva)
  Array{Card, 1}(), #asztal ures
  CardSet([t9, tU]), #talon
  [
    PlayerState(
      Player(1),
      CardSet([pA,pT,pK,pF, mK,mU,m8]), #felvevo lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(2),
      CardSet([pU,p9,mA,mT,m7]), #2. jatekos lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(3),
      CardSet([p8,p7, m9,mF]), #3. jatekos lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    )
  ],
  p1 #current player
)

##############
#Tests
##############
