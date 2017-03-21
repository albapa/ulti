include("basics.jl")
include("IntSet32.jl")
import DataStructures
import Base: copy, union, in, intersect
# import Base: complement

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

#TODO: Performance: everything Int and native IntSet32

# typealias CardSet IntSet32
# CardSet(cards::Array{Card, 1}) = IntSet32([Int(card) for card in cards])
typealias CardSet DataStructures.IntSet
CardSet(cards::Array{Card, 1}) = DataStructures.IntSet([Int(card) for card in cards])

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
hanyAsz(ca::Vector{Card}) = hanyAsz(CardSet(ca))
hanyTizes(cs::CardSet) = length(intersect(cs, tizesek))
hanyTizes(ca::Vector{Card}) = hanyTizes(CardSet(ca))
hanyAT(cs::CardSet) = length(intersect(cs, AT))
hanyAT(ca::Vector{Card}) = hanyAT(CardSet(ca))
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

nextPlayer(pl::Player) = Player(Int(pl) % 3 + 1)
nextPlayer(pl::Player, offset::Int) = Player(mod(Int(pl) - 1 + offset, 3) + 1)
previousPlayer(pl::Player) = nextPlayer(pl, -1)
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

function copy(ps::PlayerState)    
    PlayerState(ps.player, copy(ps.hand), copy(ps.discard), ps.negyven, ps.husz)
end

#The game state
#IMPORTANT: as it is copied with shallow copy
#   any field that changes across moves must not be referenced
#   or should be explicitly deep copied by the copy constructor
type GameState
    contract::Contract  #mi a bemondas

    deck::CardSet       # leosztatlan pakli
    asztal::Array{Card}  # asztal kozepe - here order matters (pl. 🌰K-ra adu 🎃9 nem ugyanaz mint adu 🎃9-re 🌰K dobas: az egyikre adut kell tenni, a masikra makkot ha van) thus it is not a set
    talon::CardSet      # talon

    # playerStates::Array{PlayerState}
    playerStates::Tuple{PlayerState,PlayerState,PlayerState}

    currentPlayer::Player
    currentSuit::Suit
    lastTrick::Player       #utolso utes
    lastTrick7::Player      #utolso utes adu hetessel
    butLastTrick8::Player   #utolso elotti utes adu 8-assal
    adu7kiment::Bool
    adu8kiment::Bool
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
    function GameState(contract::Contract, deck::CardSet, asztal::Array{Card,1},
        talon::CardSet, playerStates::Tuple{PlayerState,PlayerState,PlayerState}, currentPlayer::Player=p1,
        currentSuit::Suit=undecided, lastTrick::Player = pX , lastTrick7::Player = pX,
        butLastTrick8::Player = pX , adu7kiment=false, adu8kiment=false,
        lastTrickFogottUlti::Player=pX, tricks::Int = 0, felvevoTricks = 0, ellenvonalTricks = 0,
        felvevoTizesek::Int=0, ellenvonalTizesek::Int=0, felvevoOsszes::Int=0, ellenvonalOsszes::Int=0)

      new(contract, deck, asztal, talon, playerStates, currentPlayer, currentSuit, lastTrick, lastTrick7, butLastTrick8, adu7kiment, adu8kiment, lastTrickFogottUlti, tricks, felvevoTricks, ellenvonalTricks, felvevoTizesek, ellenvonalTizesek, felvevoOsszes, ellenvonalOsszes)
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

#copy constructor
function copy(g::GameState)    
    ps2 = (copy(g.playerStates[1]), copy(g.playerStates[2]), copy(g.playerStates[3]))

    GameState(copy(g.contract), copy(g.deck), copy(g.asztal), 
        copy(g.talon), ps2, g.currentPlayer, 
        g.currentSuit, g.lastTrick, g.lastTrick7, g.butLastTrick8, 
        g.adu7kiment, g.adu8kiment, g.lastTrickFogottUlti, g.tricks, 
        g.felvevoTricks, g.ellenvonalTricks, g.felvevoTizesek, 
        g.ellenvonalTizesek, g.felvevoOsszes, g.ellenvonalOsszes)
end

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
#Note: special for asztal which is an array not a set (order matters)?
function move!(card::Card, from::CardSet, to::Vector{Card})
    push!(to, card)
    pop!(from, Int(card))
end

function move!(card::Card, from::CardSet, to::CardSet)
    push!(to, Int(card))
    pop!(from, Int(card))
end

function move!(cards::Vector{Card}, to::Vector{Card})
    append!(to, cards)
    empty!(cards)
end

function ps(g::GameState, player::Player)
    return g.playerStates[Int(player)]
end

function ps(g::GameState, i::Int)
    return g.playerStates[i]
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
        if g.tricks == 10 || (g.tricks < 9 && g.adu7kiment) #TODO fix
            if ce.modosito == elolrol return -ce.val end #elolrol szimplan bukik
            if isempty(ce.kon) return -2 * ce.val end #hatulrol duplan bukik #TODO kiveve ha nem volt ott a hetes
            return -3 * div(ce.val, 2) #hatulrol kotraval triplan bukik, rekontraval 6x, stb.
        end
        return 0    #meg nem tudjuk

    elseif ce.bem == repulo
        if g.butLastTrick8 == p1 return ce.val end #megvan
        if g.tricks >= 9 || (g.tricks < 8 && g.adu8kiment) return -ce.val end #bukott
        return 0    #meg nem tudjuk

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
        if hanyAsz(g.playerStates[1].discard) == 4 #negy aszt vitt
            return ce.val
        end
        ellenvonalUtesek = union(g.playerStates[2].discard, g.playerStates[3].discard, g.talon)
        if hanyAsz(ellenvonalUtesek) > 0 #legalabb egy asz az ellenvonal utesei kozott
            return -ce.val
        end
        return 0

    elseif ce.bem == negyTizes
        if hanyTizes(g.playerStates[1].discard) == 4 #negy tizest vitt
            return ce.val
        end
        ellenvonalUtesek = union(g.playerStates[2].discard, g.playerStates[3].discard, g.talon)
        if hanyTizes(ellenvonalUtesek) > 0 #legalabb egy tizes az ellenvonal utesei kozott
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

function showCard(ca::Vector{Card}, io::IO=STDOUT, shortForm=false)
    if isempty(ca) return end
    for card in ca
        showCard(card, io)
    end
end

function showCard(cs::CardSet, io::IO=STDOUT, shortForm=false)
    if isempty(cs) return end
    toPrint = sort([Card(card) for card in cs], rev=true) #print in order
    showCard(toPrint, io, shortForm)
end

function show(io::IO, pstate::Array{PlayerState, 1})
    for pl in pstate
        print(io, playerNames[pl.player]); print(io, ": ")
        showCard(pl.hand, io)
        println(io); println(io)
    end
    println(io); println(io)
    for pl in pstate
        print(io, playerNames[pl.player]); print(io, " ütései: ")
        showCard(pl.discard, io)
        println(io)
    end
end

function show(io::IO, g::GameState)
    println(io, g.contract); println(io)
    print(io, "Asztal: "); showCard(g.asztal, io); println(io); println(io); println(io)
    show(io, g.playerStates)
    print(io, "Talon: " ); showCard(g.talon, io); println(io)

    print(io, "\n$(g.currentPlayer) jön. Lehetséges hívasok: "); showCard(validMoves(g))
    print(io, "\n\nÜtések száma: $(g.tricks)")
    print(io, "\nNyeremény: $(score(g))")
    # print(io, "\nadu: $(g.contract.suit)")
    print(io, "\nFelvevő    Tízesek:$(g.felvevoTizesek)    Összes:$(g.felvevoOsszes)    Ütések:$(g.felvevoTricks)")
    print(io, "\nEllenvonal Tízesek:$(g.ellenvonalTizesek)    Összes:$(g.ellenvonalOsszes)    Ütések:$(g.ellenvonalTricks)")
    print(io, "\nUtolsó ütés:$(g.lastTrick)    adu 7 utolsó:$(g.lastTrick7)    adu 8 utolsó előtti:$(g.butLastTrick8)    csendes ulti bukott:$(g.lastTrickFogottUlti) \nadu 7 kiment:$(g.adu7kiment) adu 8 kiment:$(g.adu8kiment)")
end

#The valid card to play in this trick (if there is already a card on the table)
function validMoves(g)
    valid = copy(ps(g, g.currentPlayer).hand) #TODO not necessary if on stack

    if length(valid) <= 1 return valid end

    #sorrend: felulutni szinbol, szin, felulutni adu, adu, egyeb
    if length(g.asztal) > 0 #mar van egy szin
        assert(g.currentSuit != undecided)
        enSuit = sameSuit(valid, g.currentSuit)
        if length(enSuit) > 0
            enSuitLarger = CardSet([x for x in enSuit if trumps(Card(x), g.asztal, g.contract.suit)])
            valid = length(enSuitLarger) > 0 ? enSuitLarger : enSuit
        elseif g.contract.suit <= p #szines jatek -> adu?
            myTrumps = intersect(szinek[g.contract.suit], valid) #ha nincs szin adu
            if length(myTrumps) > 0
                myTrumpsLarger = CardSet([x for x in myTrumps if trumps(Card(x), g.asztal, g.contract.suit)]) #ha van mar adu azt is felul kell utni
                valid = length(myTrumpsLarger) > 0 ? myTrumpsLarger : myTrumps
            end
        end
    end

    #adu 7-8 ulti rep nem lehet ido elott

    #ulti-repulonel valaszthatunk
    if length(valid) == 2 && g.contract.suit <= p &&
        Card(g.contract.suit, _7) in valid && Card(g.contract.suit, _8) in valid &&
        isUlti(g.contract) && isRepulo(g.contract)
        #NOP
    elseif length(valid) > 1 && isUlti(g.contract)
        setdiff!(valid, Int(Card(g.contract.suit, _7)))
    end
    if length(valid) > 1 && isRepulo(g.contract)
        adu8 = Card(g.contract.suit, _8)
        if g.tricks < 9 setdiff!(valid, Int(adu8)) #nem szabad kijatszani
        elseif g.tricks == 9 && adu8 in valid
            valid = CardSet(Int(adu8)) #kotelezo kijatszani
        end
    end

    return valid
end


function negyvenHusz(ps::PlayerState, trump::Suit)
    negyven = husz = 0
    for suit in [t,z,m,p]
        if issubset(CardSet([Card(suit, F), Card(suit, K)]), ps.hand)
            if suit == trump negyven += 1
            else husz +=1
            end
        end
    end
end

function newState(gOld::GameState, contract::Contract)
    throw("implement me!")
end

function newState(gOld::GameState, negyven::Int, husz::Int)
    if g.tricks > 1 throw(ArgumentError("negyven, husz csak a jatek elejen")) end
    if g.contract.suit > p throw(ArgumentError("szines jatek kell")) end
    if negyven > 1 || husz > 3 || husz < 0 || negyven < 0 throw(ArgumentError()) end
    (negy, hu) = negyvenHusz(ps(g, g.currentPlayer), g.contract.suit)
    if negy < negyven || hu < husz
        throw(ArgumentError("nincs negyven/husz"))
    end

    g = copy(gOld)
    ps(g, g.currentPlayer).negyven += negyven
    ps(g, g.currentPlayer).husz += husz

    return g
end

function newState(gOld::GameState, card::Card)
    g = copy(gOld) #TODO make sure consistency - deep copy for immutability, or custom copy constructor for speed?
    move!(card, ps(g, g.currentPlayer).hand, g.asztal)

    if card == Card(g.contract.suit, _7) g.adu7kiment = true end
    if card == Card(g.contract.suit, _8) g.adu8kiment = true end

    if length(g.asztal) == 1 #uj szin
        g.currentSuit = SuitFace(card)[1]
    end

    if length(g.asztal) == 3 #kor vege
        tizasz = hanyAT(g.asztal)
        bestCard = largestCard(g.asztal, g.contract.suit)
        if bestCard == 3
            whoseTrick = g.currentPlayer
        elseif bestCard == 1
            whoseTrick = nextPlayer(g.currentPlayer)
        else bestCard == 2
            whoseTrick = nextPlayer(nextPlayer(g.currentPlayer))
        end

        #update variables
        g.tricks += 1
        if g.tricks == 10
            g.lastTrick = whoseTrick

            if g.lastTrick == p1 #utolso utes = 10
                g.felvevoTizesek += 10
                g.felvevoOsszes += 10
            else
                g.ellenvonalTizesek += 10
                g.ellenvonalOsszes+= 10
            end


            if g.contract.suit <= p
                trump7 = Card(g.contract.suit, _7)
                if trump7 == g.asztal[bestCard]
                    g.lastTrick7 = whoseTrick
                else
                    holaHetes = findfirst(g.asztal, trump7)
                    if holaHetes == 3 g.lastTrickFogottUlti = g.currentPlayer
                    elseif holaHetes == 1 g.lastTrickFogottUlti = nextPlayer(g.currentPlayer)
                    elseif holaHetes == 2 g.lastTrickFogottUlti = nextPlayer(nextPlayer(g.currentPlayer))
                    end
                end
            end
        end

        #repulo
        if g.tricks == 9 && g.contract.suit <= p
            trump8 = Card(g.contract.suit, _8)
            if trump8 == g.asztal[bestCard]
                g.butLastTrick8 = whoseTrick
            end
        end

        if whoseTrick == p1
            g.felvevoTricks += 1
            g.felvevoTizesek += tizasz * 10
            g.felvevoOsszes+= tizasz * 10
        else
            g.ellenvonalTricks += 1
            g.ellenvonalTizesek += tizasz * 10
            g.ellenvonalOsszes+= tizasz * 10
        end

        move!(g.asztal, ps(g, whoseTrick).discard)

        g.currentSuit = undecided
        g.currentPlayer = whoseTrick

    else #no trick yet
        g.currentPlayer = nextPlayer(g.currentPlayer)
    end

    return g
end

##############
#Tests
##############
