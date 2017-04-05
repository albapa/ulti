include("basics.jl")
# include("IntSet32.jl")
import DataStructures
import Base: copy, union, in, intersect
import Combinatorics: Combinations
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
# typealias CardSet DataStructures.IntSet
# CardSet(cards::Array{Card, 1}) = DataStructures.IntSet([Int(card) for card in cards])

typealias CardSet CardSet32

hanyAsz(cs::CardSet) = length(intersect(cs, A))
hanyAsz(ca::Vector{Card}) = hanyAsz(CardSet(ca))
hanyTizes(cs::CardSet) = length(intersect(cs, T))
hanyTizes(ca::Vector{Card}) = hanyTizes(CardSet(ca))
hanyAT(cs::CardSet) = length(intersect(cs, AT))
hanyAT(ca::Vector{Card}) = hanyAT(CardSet(ca))
sameSuit(cs::CardSet, suit::Suit) = intersect(cs, suit)
sameSuit(cs1::CardSet, cs2::CardSet, suit::Suit) = union(cs1, cs2) in suit
function sameSuitLarger(cs::CardSet, suit::Suit, card::Card)
#TODO - supporting structure?
end
aduk(cs::CardSet, adu::Suit) = intersect(cs, adu)

#Players
typealias Player UInt8
    p1=UInt8(1) 
    p2=UInt8(2) 
    p3=UInt8(3) 
    p4=UInt8(4) 
    p5=UInt8(5) 
    p6=UInt8(6) 
    pX=UInt8(7)
const playerNames = Dict([
    (p1, "Alfa "),
    (p2, "Béla "),
    (p3, "Gamma"),
    (p4, "Delta"),
    (p5, "Epszi"),
    (p6, "Tétova"),
    (pX, ""), ]) #barmelyik jatekos (null)

nextPlayer(pl::Player) = Player(pl % 3 + 1)
nextPlayer(pl::Player, offset::Int) = Player(mod(pl - 1 + offset, 3) + 1)
previousPlayer(pl::Player) = nextPlayer(pl, -1)
# const FELVEVO = p1
# const ELLENVONAL = [p2, p3]
# const ELLENFEL1 = p2
# const ELLENFEL2 = p3

immutable PlayerState
    player::Player
    hand::CardSet
    discard::CardSet
    negyven::UInt8 #0 vagy 1
    husz::UInt8 #0-3
end

function newHand(ps::PlayerState, hand::CardSet)
    PlayerState(ps.player, hand, ps.discard, ps.negyven, ps.husz)
end

function newDiscard(ps::PlayerState, discard::CardSet)
    PlayerState(ps.player, ps.hand, discard, ps.negyven, ps.husz)
end

function newNegyvenHusz(ps::PlayerState, negyven::UInt8, husz::UInt8)
    PlayerState(ps.player, ps.hand, ps.discard, negyven, husz)
end

#The game state
#IMPORTANT: as it is copied with shallow copy
#   any field (such as contract) that changes across moves must not be referenced
#   or should be explicitly deep copied by the copy constructor
immutable GameState
    contract::Contract  #mi a bemondas

    pakli::CardSet       # leosztatlan pakli
    asztal::CardSet  # asztal kozepe - here order matters (pl. 🌰K-ra adu 🎃9 nem ugyanaz mint adu 🎃9-re 🌰K dobas: az egyikre adut kell tenni, a masikra makkot ha van) thus it is not a set
    talon::CardSet      # talon

    # playerStates::Array{PlayerState}
    playerStates::Tuple{PlayerState,PlayerState,PlayerState}

    currentPlayer::Player
    currentSuit::Suit
    whoseTrick::Player  #o viszi az utest eddig
    lastTrick::Player       #utolso utes
    lastTrick7::Player      #utolso utes adu hetessel
    butLastTrick8::Player   #utolso elotti utes adu 8-assal
    adu7kiment::Player
    adu8kiment::Player
    lastTrickFogottUlti::Player #elbukta a (csendes) ultit
    tricks::UInt8             #number of tricks
    felvevoTricks::UInt8      #number of tricks
    ellenvonalTricks::UInt8   #number of tricks
    felvevoTizesek::UInt8     #tizesek + aszok + utolso utes
    ellenvonalTizesek::UInt8  #tizesek + aszok + utolso utes
    felvevoOsszes::UInt8      #tizesek + aszok + utolso utes + 20 + 40
    ellenvonalOsszes::UInt8   #tizesek + aszok + utolso utes + 20 + 40

    #default constructor
    function GameState(contract::Contract, pakli::CardSet, asztal::CardSet,
        talon::CardSet, playerStates::Tuple{PlayerState,PlayerState,PlayerState}, 
        currentPlayer::Player=p1, currentSuit::Suit=notrump, whoseTrick::Player=pX, 
        lastTrick::Player = pX , lastTrick7::Player = pX,
        butLastTrick8::Player = pX , adu7kiment::Player=pX, adu8kiment::Player=pX,
        lastTrickFogottUlti::Player=pX, tricks::UInt8 = 0x0, felvevoTricks = 0x0, ellenvonalTricks = 0x0,
        felvevoTizesek::UInt8=0x0, ellenvonalTizesek::UInt8=0x0, felvevoOsszes::UInt8=0x0, ellenvonalOsszes::UInt8=0x0)

      new(contract, pakli, asztal, talon, playerStates, currentPlayer, currentSuit, whoseTrick, lastTrick, lastTrick7, butLastTrick8, adu7kiment, adu8kiment, lastTrickFogottUlti, tricks, felvevoTricks, ellenvonalTricks, felvevoTizesek, ellenvonalTizesek, felvevoOsszes, ellenvonalOsszes)
    end

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

#TODO
# #create signature
# function serialize(stream, g::GameState)
# end

#copy constructor
# function copy(g::GameState)    
#     ps2 = (copy(g.playerStates[1]), copy(g.playerStates[2]), copy(g.playerStates[3]))

#     GameState(copy(g.contract), copy(g.pakli), copy(g.asztal), 
#         copy(g.talon), ps2, g.currentPlayer, 
#         g.currentSuit, g.lastTrick, g.lastTrick7, g.butLastTrick8, 
#         g.adu7kiment, g.adu8kiment, g.lastTrickFogottUlti, g.tricks, 
#         g.felvevoTricks, g.ellenvonalTricks, g.felvevoTizesek, 
#         g.ellenvonalTizesek, g.felvevoOsszes, g.ellenvonalOsszes)
# end

#parse a list of cards
#Format: known cards (e.g. p9) are marked suit (non-capital t,z,m,p) and face (capital 7,8,9,U,F,K,A)
#Special suits: x: any suit, tz: tok vagy zold, pmz: piros vagy makk vagy zold
#Special faces: X:any face Z:'nem fontos' [9UFK] .:Y [789UFK], explicit: pl. [AT] az asz v tizes
#Examples: "pATYY mAKX z.. tK[U987][U987]":
#Tricky case: a kicsi t tokot, a nagy T Tizest jelol a felreertesek elkerulese vegett
#Alternativ jelolesek:  also: UVJ, tizes: T vagy 10, tok: t vagy o
#Players are separated by '|' or '/'
#Contract and cards are separated by ';'
function parseCards(s::AbstractString)

    #Ideas: suit then cards x, a(du)bcd, [80%]bFK [20%E] eros(AT), xN10 (fill until 10 cards)
    #first match abcd then single cards then probabilities greedily. 
    #Q: try again if fails? how many times? maybe give warning? Try ALL?
    #bemondas: regexp for p[EHR].x[Ult|Rep|40|4A...]K*  (vagy RK, SK MK) 

    regexp = r"(?<suit>(t|z|m|p|n|x|a|b|c|d)+)(?<face>(A|T|K|F|U|9|8|7|X|Y|X|N[0-9]+)+)\s*"

    # matches = [mtch for mtch in eachmatch(regexp, s)]
    cs = Vector{CardSet}()
    for mtch in eachmatch(regexp, s)
        suits = CardSet32()
        for suit in mtch[:suit]
            suits += suitProperties[suit]
        end
        faces = CardSet32()
        for face in mtch[:face]
            faces += faceProperties[face]
        end

        push!(cs, suits * faces)
    end

    #TODO: N cards, [80%], X,Y,Z, a,b,c,d,etc.

    return cs
end

function parseManyCards(s::AbstractString)
        return [parseCards(cards) for cards in split(s, "|")]
end

#TODO
function parseState(s::String)
    if contains(s, ";")
        contractAndState = split(s, ';')
        if length(contractAndState) > 2 throw("too many ;-s") end
        contract = parseContract(contractAndState[1])
        stateS = contractAndState[2]
    else
        contract = nocontract
        stateS = s
    end

    if contains(stateS, ":") #full canonical state
        xxx = split(stateS, [':', '|']) #TODO
    else
        cards = parseManyCards(stateS)
    end



    # collections = split(s, ['|', '/'])
    # for collection in collections
    #     cs = parseCards(collection)

    # #     for c in collection
    #         suit = notrump
    #             if suit == notrump #look for first suit
    #                 #TODO
    #             end
    #     end
    # end
    # cards = Array{Array{Card, 1}, 1}()
    #parse suits, parse faces

    #deal fix cards, then coloured cards (px), then multicouloured cards (pz.) then the rest (xx, xA)
end
#match cards to a pattern
#Example: "pAKxx zT7x mKF tx" , full deck
#Eliminate by rows (every spot must have one card)
#and columns (one card can only be maximum at one place at the end)
#if no obvious step, match a card randomly
#TODO test
function matchCards(cardSlots::Vector{CardSet}, cards::CardSet)
    #build 2D binary (logical) matrix
    #see Sodoku solver at: http://www.math.cornell.edu/~mec/Summer2009/meerkamp/Site/Solving_any_Sudoku_II.html

    isDone = [false for cs in cardSlots] #mark elements committed

    (slotsByWeight, cards) = commitAllUnique(cardSlots, isDone, cards) #do twice at the beginning to make sure all simple ones are resolved before the complicated searches start
    
    while !all(isDone)
        
        #for (cs, dn) in zip(cardSlots, isDone); (print(dn), print(cs), println()) end; (print(cards), println()); for (k,v) in slotsByWeight print(" $(k) $(v)") end #DEBUG
        
        (slotsByWeight, cards) = commitAllUnique(cardSlots, isDone, cards)

        if all(isDone) break end

        #if all remaining slots are the same, distribute -> done
        if length(slotsByWeight) == 1
            for (n, indices) in slotsByWeight
                assert(length(indices) > 0)
                firstElem = cardSlots[first(indices)]
                if all(x -> cardSlots[x] == firstElem, indices) #all equal
                    if(length(firstElem * cards) < length(indices))
                        throw("not enough cards to distribute indices: $(indices) cards: $(cards)")
                    end

                    #distribute randomly
                    cardsToCommit = shuffle(rng, toArray(firstElem * cards))
                    cards = commitMany!(cardSlots, isDone, indices, cardsToCommit, cards)
                end
            end
            assert(all(isDone))
        end
        #for (cs, dn) in zip(cardSlots, isDone); (print(dn), print(cs), println()) end; (print(cards), println()); for (k,v) in slotsByWeight print(" $(k) $(v)") end #DEBUG

        if all(isDone) break end

        #look for preemptive sets (for example 3 slots with pATK, pATK, pATK that we can commit)
        foundPreemptiveSet = false
        for (n, indices) in slotsByWeight 
            if length(indices) < n 
                continue 
            end #for length x we need at least x in the set

            (firstPreemptiveSet, cardsInSet) = findPreemptiveSet(n, indices, cardSlots) #if we find one we commit immediately

            if !isempty(firstPreemptiveSet)
                assert(length(firstPreemptiveSet) == n && length(cardsInSet) == n) #exactly n cards needed
                foundPreemptiveSet = true
                # 
                #TODO: we just randomly do that 
                #we could generate all permutations if needed using Combinatorics.Permutations(toArray(cards), n)
                cardsToCommit = shuffle(rng, toArray(cards))
                cards = commitMany!(cardSlots, isDone, firstPreemptiveSet, cardsToCommit, cards)
                break
            end
        end
        
        #for (cs, dn) in zip(cardSlots, isDone); (print(dn), print(cs), println()) end; (print(cards), println()); for (k,v) in slotsByWeight print(" $(k) $(v)") end #DEBUG

        #all hard criteria fullfilled - randomly fill the rest
        if !foundPreemptiveSet
            #TODO
        end
    end

    return (cardSlots, cards)
end

#find single cards and commit them
@inline function commitAllUnique(cardSlots, isDone, cards)
    slotsByWeight = Dict{Int, Vector{Int}}()
    for i in 1:length(cardSlots)
        if isDone[i] #already done
            continue
        end

        cardSlots[i] *= cards #we cannot wish for cards not in the deck anymore
        cs = cardSlots[i]
        len = length(cs)
        if 0 == len #commit
            throw("no (matching) card - cannot fulfill criteria. index: $(i), card: $(cs), deck: $(cards)")
        elseif 1 == len #commit
            cards = commit!(isDone, i, cs, cards)
        else
             slotsByWeight[len] = push!(get(slotsByWeight, len, Vector{Int}()), i)
        end
    end

    return (slotsByWeight, cards)
end

#find the first preemptive set
function findPreemptiveSet(n, indices, cardSlots)
    for comb in combinations(indices, n) #try all combinations
        allCardsInComb = CardSet(cardSlots[comb]) #array constructor -> union
        if length(allCardsInComb) == n #n cards in n slots
            return (comb, allCardsInComb)
        end
    end
    
    return ([], CardSet()) # no preemptive set
end

function commit!(isDone, i, card, cards)
    if !(card in cards) throw("card not in cards - cannot fulfill criteria") end
    cards = cards - card
    isDone[i] = true

    return cards
end

function commitMany!(cardSlots, isDone, indices, cardsToCommit, cards)
    for (i, card) in zip(indices, cardsToCommit)
        assert(card in cardSlots[i])
        cardSlots[i] *= card

        cards = commit!(isDone, i, card, cards)
    end

    return cards
end

function ps(g::GameState, player::Player)
    return g.playerStates[player]
end

#Evaluate the score based on the game state
#if the game is over, it returns the final score
#otherwise the sum of contracts that have been decided
#notrump contracts yield 0
#TODO instead of Int, return (10,-5,-5) for proper handling of csendesUlti and csendesDuri
function score(g::GameState, ce::ContractElement)
    #TODO: maybe check after full tricks only?
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
        if g.felvevoOsszes > kiadoUtesek + g.ellenvonalOsszes #Uint(0) - Uint(20) = 236!
            return ce.val #mar barhogyan megnyertuk, akkor is ha a kiado utesek az ellenhez kerulnek
        end
        if g.ellenvonalOsszes > kiadoUtesek + g.felvevoOsszes
            return -ce.val #mar barhogyan megnyertek, akkor is ha a kiado utesek hozzam kerulnek
        end
        return 0

    elseif ce.bem == ulti
        if g.lastTrick7 == p1 return ce.val end #megvan
        if g.tricks == 10 || (g.tricks < 9 && g.adu7kiment!=pX) || (g.tricks == 9 && g.adu7kiment!=pX && !in(Card(g.contract.suit, _7), g.asztal))#TODO fix
            if ce.modosito == elolrol return -ce.val end #elolrol szimplan bukik
            if isempty(ce.kon) return -2 * ce.val end #hatulrol duplan bukik #TODO kiveve ha nem volt ott a hetes
            return -3 * div(ce.val, 2) #hatulrol kotraval triplan bukik, rekontraval 6x, stb.
        end
        return 0    #meg nem tudjuk

    elseif ce.bem == repulo
        if g.butLastTrick8 == p1 return ce.val end #megvan
        if g.tricks >= 9 || (g.tricks < 8 && g.adu8kiment!=pX) return -ce.val end #bukott
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

function print(io::IO, pstate::Tuple{PlayerState, PlayerState, PlayerState}, shortFormat::Bool=true)
    if shortFormat
        for pl in pstate
            print(io, pl.hand, true); print(io, "|")
        end
        for pl in pstate
            print(io, pl.discard, true); print(io, "|")
        end
        for pl in pstate
            print(io, pl.negyven); print(io, "|")
        end
        for pl in pstate
            print(io, pl.husz); print(io, "|")
        end
    else
        for pl in pstate
            print(io, playerNames[pl.player]); print(io, ": ")
            print(io, pl.hand, false)
            println(io); println(io)
        end
        println(io)
        for pl in pstate
            print(io, playerNames[pl.player]); print(io, " ütései: ")
            print(io, pl.discard, false)
            println(io)
        end
    end
end

display(pstate::Tuple{PlayerState, PlayerState, PlayerState}) = print(STDOUT, pstate, false)

function print(io::IO, g::GameState, shortFormat::Bool=true)
    if shortFormat
        print(io, g.contract, true); print(io, ";")
        print(io, g.playerStates, true); print(io, "|")
        print(io, g.talon, true); print(io, "|")
        print(io, g.asztal, true); print(io, "|")
        #TODO: additional parameters separated by ":"
    else
        println();print(io, g.contract, false); println(io)
        print(io, "\nAsztal: "); print(io, g.asztal, false); println(io); println(io); println(io)
        print(io, g.playerStates, false)
        print("Talon: "); print(io, g.talon, false); println(io)

        print(io, "\n$(playerNames[g.currentPlayer]) jön. Lehetséges hívasok: "); print(io, validMoves(g), false)
        print(io, "\n\nÜtések száma: $(g.tricks)")
        print(io, "\nNyeremény: $(score(g))")
        # print(io, "\nadu: $(g.contract.suit)")
        print(io, "\nFelvevő    Tízesek:$(g.felvevoTizesek)    Összes:$(g.felvevoOsszes)    Ütések:$(g.felvevoTricks)")
        print(io, "\nEllenvonal Tízesek:$(g.ellenvonalTizesek)    Összes:$(g.ellenvonalOsszes)    Ütések:$(g.ellenvonalTricks)")
        print(io, "\nUtolsó ütés:$(playerNames[g.lastTrick])    adu 7 utolsó:$(playerNames[g.lastTrick7])    adu 8 utolsó előtti:$(playerNames[g.butLastTrick8])    csendes ulti bukott:$(playerNames[g.lastTrickFogottUlti]) \nadu 7 kiment:$(playerNames[g.adu7kiment]) adu 8 kiment:$(playerNames[g.adu8kiment])")
        print(io, "\n\nID: \""); print(io, g, true); print(io, "\"")
    end    
end

display(g::GameState) = print(STDOUT, g, false)


#The valid card to play in this trick (if there is already a card on the table)
function validMoves(g)
    # valid = copy(ps(g, g.currentPlayer).hand)
    valid = ps(g, g.currentPlayer).hand #copy not necessary if on stack

    if length(valid) <= 1 return valid end

    #sorrend: felulutni szinbol, szin, felulutni adu, adu, egyeb
    if length(g.asztal) > 0 #mar van egy szin
        assert(g.currentSuit != notrump)
        enSuit = sameSuit(valid, g.currentSuit)
        if length(enSuit) > 0
            if g.currentSuit != g.contract.suit && !isempty(aduk(g.asztal, g.contract.suit)) #ha mar aduval utottek nem kell felul utni
                valid = enSuit
            else
                largestEnSuite = largestCard(g.asztal, g.currentSuit) #best in suite - ezt kell felulutni
                enSuitLarger = whichTrumps(enSuit, largestEnSuite, g.contract.suit)
                valid = length(enSuitLarger) > 0 ? enSuitLarger : enSuit
            end
        elseif g.contract.suit <= p #szines jatek -> adu?
            myTrumps = intersect(g.contract.suit, valid) #ha nincs szin adu
            if length(myTrumps) > 0 #nincs szin de van adu
                largest = largestCard(g.asztal, g.contract.suit)
                valid = myTrumps
                if SuitFace(largest)[1] == g.contract.suit #mar van adu felul kell utni
                    myTrumpsLarger = whichTrumps(myTrumps, largest, g.contract.suit) #ha van mar adu azt is felul kell utni
                    valid = length(myTrumpsLarger) > 0 ? myTrumpsLarger : myTrumps
                end
            end
        end
    end

    #adu 7-8 ulti rep nem lehet ido elott

    #ulti-repulonel valaszthatunk
    if length(valid) == 2 && g.contract.suit <= p &&
        in(Card(g.contract.suit, _7), valid) && in(Card(g.contract.suit, _8), valid) &&
        isUlti(g.contract) && isRepulo(g.contract)
        #NOP
    elseif length(valid) > 1 && isUlti(g.contract)
        valid = setdiff(valid, Card(g.contract.suit, _7))
    end
    if length(valid) > 1 && isRepulo(g.contract)
        adu8 = Card(g.contract.suit, _8)
        if g.tricks < 9 
            valid -= adu8 #nem szabad kijatszani
        elseif g.tricks == 9 && adu8 in valid
            valid = adu8 #kotelezo kijatszani
        end
    end

    return valid
end


function negyvenHusz(ps::PlayerState, trump::Suit)
    negyven = husz = 0
    for suit in [t,z,m,p]
        if issubset(union(Card(suit, F), Card(suit, K)), ps.hand)
            if suit == trump negyven += 1
            else husz +=1
            end
        end
    end
end

function newState(gOld::GameState, contract::Contract)
    throw("implement me!")
end

function newState(gOld::GameState, negyven::UInt8, husz::UInt8)
    if g.tricks > 1 throw(ArgumentError("negyven, husz csak a jatek elejen")) end
    if g.contract.suit > p throw(ArgumentError("szines jatek kell")) end
    if negyven > 1 || husz > 3 || husz < 0 || negyven < 0 throw(ArgumentError()) end
    (negy, hu) = negyvenHusz(ps(g, g.currentPlayer), g.contract.suit)
    if negy < negyven || hu < husz
        throw(ArgumentError("nincs negyven/husz"))
    end

    g = GameState(gOld)
    ps(g, g.currentPlayer).negyven += negyven
    ps(g, g.currentPlayer).husz += husz

    return g
end

function newState(g::GameState, card::Card)
    assert(length(card) == 1)

    #copy them one by one, change and reconstruct - poor man's update for immutables
    contract=g.contract; pakli=g.pakli; asztal=g.asztal; talon=g.talon;
    currentPlayer=g.currentPlayer; currentSuit=g.currentSuit; whoseTrick=g.whoseTrick; 
    lastTrick=g.lastTrick ; lastTrick7=g.lastTrick7;
    butLastTrick8=g.butLastTrick8 ; adu7kiment=g.adu7kiment; adu8kiment=g.adu8kiment;
    lastTrickFogottUlti=g.lastTrickFogottUlti; tricks=g.tricks; 
    felvevoTricks=g.felvevoTricks; ellenvonalTricks=g.ellenvonalTricks;
    felvevoTizesek=g.felvevoTizesek; ellenvonalTizesek=g.ellenvonalTizesek; 
    felvevoOsszes=g.felvevoOsszes; ellenvonalOsszes=g.ellenvonalOsszes

    playerStates = [g.playerStates[1], g.playerStates[2], g.playerStates[3]]
    # g = GameState(gOld) #TODO make sure consistency - deep copy for immutability, or custom copy constructor for speed?

    asztal = add(asztal, card)
    hand = remove(playerStates[currentPlayer].hand, card)
    playerStates[currentPlayer] = newHand(playerStates[currentPlayer], hand)

    if card == Card(contract.suit, _7) adu7kiment = currentPlayer end
    if card == Card(contract.suit, _8) adu8kiment = currentPlayer end

    if length(asztal) == 1 #uj szin
        currentSuit = SuitFace(card)[1]
        whoseTrick = currentPlayer
    else
        if trumpsAll(card, asztal, contract.suit)
            whoseTrick = currentPlayer
        end
    end

    if length(asztal) == 3 #kor vege
        tizasz = hanyAT(asztal)

        #update variables
        tricks += UInt8(1)
        if tricks == UInt8(10)
            lastTrick = whoseTrick

            if lastTrick == p1 #utolso utes = 10
                felvevoTizesek += UInt8(10)
                felvevoOsszes += UInt8(10)
            else
                ellenvonalTizesek += UInt8(10)
                ellenvonalOsszes+= UInt8(10)
            end


            if contract.suit <= p
                trump7 = Card(contract.suit, _7)
                if trump7 == largestCard(asztal, contract.suit)
                    lastTrick7 = whoseTrick
                else
                    lastTrickFogottUlti = adu7kiment #(csendes) ulti bukott
                end
            end
        end

        #repulo
        if tricks == 9 && contract.suit <= p
            trump8 = Card(contract.suit, _8)
            if trump8 == largestCard(asztal, contract.suit)
                butLastTrick8 = whoseTrick
            end
        end

        if whoseTrick == p1
            felvevoTricks += UInt8(1)
            felvevoTizesek += UInt8(tizasz * 10)
            felvevoOsszes+= UInt8(tizasz * 10)
        else
            ellenvonalTricks += UInt8(1)
            ellenvonalTizesek += UInt8(tizasz * 10)
            ellenvonalOsszes+= UInt8(tizasz * 10)
        end

        discard = add(playerStates[whoseTrick].discard, asztal)
        playerStates[whoseTrick] = newDiscard(playerStates[whoseTrick], discard)
        asztal = CardSet()

        currentSuit = notrump
        currentPlayer = whoseTrick
        whoseTrick = pX

    else #no trick yet
        currentPlayer = nextPlayer(g.currentPlayer)
    end

    return GameState(contract, pakli, asztal, talon, (playerStates[1],playerStates[2],playerStates[3]), currentPlayer, currentSuit, whoseTrick, lastTrick, lastTrick7, butLastTrick8, adu7kiment, adu8kiment, lastTrickFogottUlti, tricks, felvevoTricks, ellenvonalTricks, felvevoTizesek, ellenvonalTizesek, felvevoOsszes, ellenvonalOsszes)

end

##############
#Tests
##############

function engineTest()
    matchCards([tA, tK, tF+tA+tU+t8, tU, tF+tA+tU+t8, tF+tA+tU+t8+t7], t)
end

function parseTest()
    parseManyCards("pApTpKpUp7mKmUm8z9tT")
    parseManyCards("pATKU7 mKU8 z9 tT")
    # parseManyCards("pApTpKpUp7mKmUm8z9tT;pFp9p8mAmFm7zKzFz7tF;mTm9zAzTzUz8tAtKt8t7")
    parseManyCards("pApTpKpUp7mKmUm8z9tT|pFp9p8mAmFm7zKzFz7tF|mTm9zAzTzUz8tAtKt8t7")
    parseManyCards("pATKU7 mKU8 z9 tT | pF98 mAF7 zKF7 tF | mT9 zATU8 tAK87")
    # parseManyCards("❤️️ ️️A ❤️️ ️️T ❤️️ ️️K ❤️️ ️️U ❤️️ ️️7 🌰 K 🌰 U 🌰 8 🍃 9 🎃 T | ❤️️️️ ️️F ❤️️ ️️9 ❤️️ ️️8 🌰 A 🌰 F 🌰 7 🍃 K 🍃 F 🍃 7 🎃 F |  T 🌰 9 🍃 A 🍃 T 🍃 U 🍃 8 🎃 A 🎃 K 🎃 8 🎃 7", )
    parseManyCards("pAKXX mTXX tX zA7N")
    parseManyCards("xXXXXXXXXXX")
    parseManyCards("xXXXXXXXXXXXX|xXXXXXXXXXX|xXXXXXXXXXX")
    parseManyCards("aAXX7 bATXX cXX")
    parseManyCards("aAXX7 bATXX cXX dXX")
    parseManyCards("[80%]aXXXX [10%]aXXXXX [5%]aXXX [5%]aXXXXXX xN10")
    #hibas

    parseContract("pEUltKE")
    parseContract("pRep")
    parseContract("Ep") #piros parti
    parseContract("EpEK") #elolrol kontra parti
    parseContract("EpHK") #elolrol kontra parti
    parseContract("EpEKHRK") #elolrol kontra hatulrol rekontra
    parseContract("pUltRep4A") #parti
    parseContract("p EP RRep RCsu") #parti
    parseContract("4T") #szintelen 4T
    parseContract("H Bet") #szintelen betli
    parseContract("H pTbet")
end
