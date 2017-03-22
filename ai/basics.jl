##############
#Cards, Rules and helper functions
##############
include("IntSet32.jl")
using Memoize
import Base: show, <, copy
DEBUG = true
UNSAFE = false #assert, type safety, etc. off

#The 32 Cards
#Tok 7es-tol (t7) piros Aszig (pA).
#Note: az also U, mint "Unter Knabe" from the original German deck

t7 = CardSet32(UInt32(1) << 0)
t8 = CardSet32(UInt32(1) << 1)
t9 = CardSet32(UInt32(1) << 2)
tU = CardSet32(UInt32(1) << 3)
tF = CardSet32(UInt32(1) << 4)
tK = CardSet32(UInt32(1) << 5)
tT = CardSet32(UInt32(1) << 6)
tA = CardSet32(UInt32(1) << 7)

z7 = CardSet32(UInt32(1) << 8 )
z8 = CardSet32(UInt32(1) << 9 )
z9 = CardSet32(UInt32(1) << 10)
zU = CardSet32(UInt32(1) << 11)
zF = CardSet32(UInt32(1) << 12)
zK = CardSet32(UInt32(1) << 13)
zT = CardSet32(UInt32(1) << 14)
zA = CardSet32(UInt32(1) << 15)

m7 = CardSet32(UInt32(1) << 16)
m8 = CardSet32(UInt32(1) << 17)
m9 = CardSet32(UInt32(1) << 18)
mU = CardSet32(UInt32(1) << 19)
mF = CardSet32(UInt32(1) << 20)
mK = CardSet32(UInt32(1) << 21)
mT = CardSet32(UInt32(1) << 22)
mA = CardSet32(UInt32(1) << 23)

p7 = CardSet32(UInt32(1) << 24)
p8 = CardSet32(UInt32(1) << 25)
p9 = CardSet32(UInt32(1) << 26)
pU = CardSet32(UInt32(1) << 27)
pF = CardSet32(UInt32(1) << 28)
pK = CardSet32(UInt32(1) << 29)
pT = CardSet32(UInt32(1) << 30)
pA = CardSet32(UInt32(1) << 31)

const deck = Dict([
    t7 => ("t7", "🎃 7"), t8 => ("t8", "🎃 8"), t9 => ("t9", "🎃 9"), tU => ("tU", "🎃 U"), tF => ("tF", "🎃 F"), tK => ("tK", "🎃 K"), tT => ("tT", "🎃 T"), tA => ("tA", "🎃 A"),
    z7 => ("z7", "🍃 7"), z8 => ("z8", "🍃 8"), z9 => ("z9", "🍃 9"), zU => ("zU", "🍃 U"), zF => ("zF", "🍃 F"), zK => ("zK", "🍃 K"), zT => ("zT", "🍃 T"), zA => ("zA", "🍃 A"),
    m7 => ("m7", "🌰 7"), m8 => ("m8", "🌰 8"), m9 => ("m9", "🌰 9"), mU => ("mU", "🌰 U"), mF => ("mF", "🌰 F"), mK => ("mK", "🌰 K"), mT => ("mT", "🌰 T"), mA => ("mA", "🌰 A"),
    p7 => ("p7", "❤️️ ️️7"), p8 => ("p8", "❤️️ ️️8"), p9 => ("p9", "❤️️ ️️9"), pU => ("pU", "❤️️ ️️U"), pF => ("pF", "❤️️️️ ️️F"), pK => ("pK", "❤️️ ️️K"), pT => ("pT", "❤️️ ️️T"), pA => ("pA", "❤️️ ️️A")])


function show(ca::Vector{CardSet32}, io::IO=STDOUT, shortForm=false)
    if isempty(ca) return end
    for card in ca
      shortForm ? print(io, deck[card][1]): print(io, deck[card][2], " ")
    end
end

function show(cs::CardSet32, io::IO=STDOUT, shortForm=false)
    if isempty(cs) return end
    for card in cs
      shortForm ? print(io, deck[card][1]): print(io, deck[card][2], " ")
    end
end


typealias Suit Int
    t = 0 #Tök
    z = 1 #Zöld
    m = 2 #Makk
    p = 3 #Piros
    notrump = 4 #Szín nélküli (ászkirályos)
    undecided = 5 #Még nem tudjuk (hátulról bemondott négy tízesnélÖ
const suitProperties = Dict([
    (t, (["Tök", "tok", "🎃", "t"], 3)),
    (z, (["Zöld", "zold", "🍃", "z"], 4)),
    (m, (["Makk", "🌰", "m"], 5)),
    (p, (["Piros", "❤️️", "p"], 6))]) #Halloween-kor TOK = 7 :)

typealias Face Int
    _7 = 0 #hetes
    _8 = 1 #nyolcas
    _9 = 2 #kilences
    # _10 = 2.5 #tizes (szintelen jateknal)
    U = 3 #alsó
    F = 4 #felső
    K = 5 #király
    T = 6 #tízes
    A = 7 #ász
# const faceProperties = Dict([
#     (_7, (["Hetes", "7"], 3)),
# ) :)

#TODO const faceProperties = Dict([(t, ("Tök", 3)), (z, ("Zöld", 4)), (m, ("Makk", 5)), (p, ("Piros", 6))]) #Halloween-kor TOK = 7 :)


const suitFace = Dict([
    t7 => (t, _7), t8 => (t, _8), t9 => (t, _9), tU => (t, U), tF => (t, F), tK => (t, K), tT => (t, T), tA => (t, A),
    z7 => (z, _7), z8 => (z, _8), z9 => (z, _9), zU => (z, U), zF => (z, F), zK => (z, K), zT => (z, T), zA => (z, A),
    m7 => (m, _7), m8 => (m, _8), m9 => (m, _9), mU => (m, U), mF => (m, F), mK => (m, K), mT => (m, T), mA => (m, A),
    p7 => (p, _7), p8 => (p, _8), p9 => (p, _9), pU => (p, U), pF => (p,F), pK => (p, K), pT => (p, T), pA => (p, A),
    (t, _7) => t7, (t, _8) => t8, (t, _9) => t9, (t, U) => tU, (t, F) => tF, (t, K) => tK, (t, T) => tT, (t, A) => tA,
    (z, _7) => z7, (z, _8) => z8, (z, _9) => z9, (z, U) => zU, (z, F) => zF, (z, K) => zK, (z, T) => zT, (z, A) => zA,
    (m, _7) => m7, (m, _8) => m8, (m, _9) => m9, (m, U) => mU, (m, F) => mF, (m, K) => mK, (m, T) => mT, (m, A) => mA,
    (p, _7) => p7, (p, _8) => p8, (p, _9) => p9, (p, U) => pU, (p, F) => pF, (p, K) => pK, (p, T) => pT, (p, A) => pA])


SuitFace(card::Card) = suitFace[card]
Card(suit::Suit, face::Face) = suitFace[(suit, face)]

#compare two cards using the trump suit
function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    else
        face1 = face1
        face2 = face2
        if trump == notrump #szintelen jateknal a tizes alulra megy, a kilences es az also koze
            if _9 < face1 != T face1 += 4 end #UFK a T fole
            if _9 < face2 != T face2 += 4 end #UFK a T fole
        end
        return face1 > face2
    end
end

#support structure for trumping
largerThan = Dict{Tuple{Card, Suit}, CardSet32}()
for (card1, x) in deck
    for (card2, x) in deck
        for trump in [t, z, m, p, notrump]
            if !haskey(largerThan, (card1, trump)) 
                largerThan[(card1, trump)] = CardSet32()
            end
            if trumps(card2, card1, trump)
                largerThan[(card1, trump)] = union(card2, largerThan[(card1, trump)])
            end
        end
    end
end
function whichTrumps(cards::CardSet32, card::Card, trump::Suit)
    intersect(cards, largerThan[(card, trump)])
end

#returns the largest card in a set using the trump suit
@memoize Dict function largestCard(cards::CardSet32, trump::Suit, suit::Suit=trump) #TODO add currentSuit handling
    assert(length(cards) > 0)

    if length(cards) == 1 return cards end
    card = first(cards)
    largerThanFirst = whichTrumps(cards, card, trump)
    if isempty(largerThanFirst) 
        if trumpsAll(card, setdiff(cards, card), trump) #if we have no trump, there is no largest card
            return card
        else
            throw(ArgumentError("no largest card in set - define suit!"))
            # return CardSet32()
        end
    else
        return largestCard(largerThanFirst, trump)
    end
end

#compare one card to a set using the trump suit
@memoize Dict function trumpsAll(card1::Card, cards::CardSet32, trump::Suit) 
    for card in cards
        if trumps(card, card1, trump) return false end
    end
    return true #no card trumped me
    # isempty(intersect(cards, largerThan[(card1, trump)])) #problem: suit (mA does not trump zT if trump is p)
end

#Bemondasok
# abban a sorrendben, ahogy egymashoz fuzik oket (ulti-repulo-40_100-negyAsz-durchmars)
typealias AlapBemondas Int
    semmi = 0 #amig nincs semmi
    ulti = 1
    repulo = 2
    negyvenSzaz = 3
    huszSzaz = 4
    negyAsz = 5
    durchmars = 6
    redurchmars = 7
    parti = passz = 8
    betli = 9
    rebetli = 10
    negyTizes = 11
    csendesUlti = 12
    csendesDuri = 13
    
#Bemondasok erteke es nevei (elso nev lesz kiirva)
const alapBemondasProperties = Dict([
  (semmi,       (0, ["", "semmi"])),
  (ulti,        (4, ["Ulti", "ultimo"])),
  (repulo,      (4, ["Repülő", "repulo"], )),
  (negyvenSzaz, (4, ["40-100", "40 100", "40_100", "negyvenSzaz", "negyvenSzáz", "Negyven Szaz", "Negyven Száz"])),
  (huszSzaz,    (8, ["20-100", "20 100", "20_100", "huszSzaz", "húszSzáz", "Husz Szaz", "Húsz Száz"])),
  (negyAsz,     (4, ["4 Ász", "4 Asz", "negyAsz", "NégyÁsz", "Negy Asz", "Négy Ász"])),
  (durchmars,   (6, ["Durchmars"])),
  (redurchmars, (12, ["Terített Durchmars", "redurchmars"])),
  (parti,       (1, ["Passz", "Parti"])),
  (betli,       (30, ["Betli"])), #mert szintelen, nincs szorzo
  (rebetli,     (20, ["Terített Betli", "rebetli"])),
  (negyTizes,   (55, ["4 Tízes", "4 Tizes", "negyTizes", "NégyTízes", "Negy Tizes", "Négy Tízes"])),
])

#Modosito szorzok elolrol bemondott vagy ramondott bemondasokra
typealias Modosito Int
    elolrol =  4
    ramondva = 2
    hatulrol = 1

const modositoProperties = Dict([
  (elolrol,  ["Elölről",  "Elolrol",  "E"]),
  (ramondva, ["Rámondva", "ramondva", "R"]),
  (hatulrol, ["Hátulról", "hatulrol", "H"]),
])


typealias Kontra Int
    EK = 4
    HK = 2

const kontraProperties = Dict([
  (EK, ["Elölről kontra",  "EK"]),
  (EK, ["Hátulról kontra", "HK"]),
])
typealias Kontrak Array{Kontra, 1} #pl. Kontrak([EK,EK,HK]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x

# function show(Kontrak) end #kiirja a kontra, re, szub, mord, stb. -t

#Egy alapbemondas modositokkal
immutable ContractElement
    modosito::Modosito
    bem::AlapBemondas
    kon::Kontrak
    val::Number
 end

#A bemondas
immutable Contract
    suit::Suit
    contracts::Array{ContractElement}
    totalvalue::Number
end

function copy(contract::Contract)
    #TODO: deep copy of contracts? - maybe not for performance reasons
    Contract(contract.suit, contract.contracts, contract.totalvalue)
end

function isUlti(contract::Contract)
    for ce in contract.contracts
        if ce.bem == ulti
            return true
        end
    end
    return false
end

function isRepulo(contract::Contract)
    for ce in contract.contracts
        if ce.bem == repulo
            return true
        end
    end
    return false
end

contractValues = Dict{Tuple{Suit,AlapBemondas,Modosito}, Int}()
#TODO mit lehet elolrol hatulrol es ramondva bemondani
#szines bemondasok
for suit in [t, z, m, p]
    for bem in [parti, negyvenSzaz, ulti, repulo, negyAsz, durchmars, huszSzaz, rebetli, redurchmars]
        for honnan in [elolrol, ramondva, hatulrol]
            contractValues[(suit, bem, honnan)] = Int(honnan) * suitProperties[suit][2] * alapBemondasProperties[bem][1]
        end
    end
end
#negy tizes
for suit in [t,z,m,p]
    contractValues[(suit, negyTizes, ramondva)] = 192
    contractValues[(suit, negyTizes, hatulrol)] = 55
end
#szintelen bemondasok
contractValues[(undecided, negyTizes, hatulrol)] = 55
contractValues[(notrump, betli, hatulrol)] = 30
contractValues[(notrump, redurchmars, hatulrol)] = 144

#all the strings needed for parsing lookups
# parseTokens = Vector()
# for properties in [suitProperties, faceProperties, deck, alapBemondasProperties, modositoProperties, kontraProperties]
#     for (key, val) in properties
#       #TODO
#         if isa(String, val)
#     end
# end
#
function show(io::IO, contract::Contract, shortFormat=false)
    print(io, "Bemondás: ")

end

function parseContract(contract::String)

end

##############
#Tests
##############
