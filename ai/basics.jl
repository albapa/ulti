##############
#Cards, Rules and helper functions
##############
include("IntSet32.jl")
using Memoize
import Base: show, <, copy, print, isequal, ==
DEBUG = true
UNSAFE = false #assert, type safety, etc. off

#The 32 Cards
#Tok 7es-tol (t7) piros Aszig (pA).
#Note: az also U, mint "Unter Knabe" from the original German deck

const t7 = CardSet32(UInt32(1) << 0)
const t8 = CardSet32(UInt32(1) << 1)
const t9 = CardSet32(UInt32(1) << 2)
const tU = CardSet32(UInt32(1) << 3)
const tF = CardSet32(UInt32(1) << 4)
const tK = CardSet32(UInt32(1) << 5)
const tT = CardSet32(UInt32(1) << 6)
const tA = CardSet32(UInt32(1) << 7)

const z7 = CardSet32(UInt32(1) << 8 )
const z8 = CardSet32(UInt32(1) << 9 )
const z9 = CardSet32(UInt32(1) << 10)
const zU = CardSet32(UInt32(1) << 11)
const zF = CardSet32(UInt32(1) << 12)
const zK = CardSet32(UInt32(1) << 13)
const zT = CardSet32(UInt32(1) << 14)
const zA = CardSet32(UInt32(1) << 15)

const m7 = CardSet32(UInt32(1) << 16)
const m8 = CardSet32(UInt32(1) << 17)
const m9 = CardSet32(UInt32(1) << 18)
const mU = CardSet32(UInt32(1) << 19)
const mF = CardSet32(UInt32(1) << 20)
const mK = CardSet32(UInt32(1) << 21)
const mT = CardSet32(UInt32(1) << 22)
const mA = CardSet32(UInt32(1) << 23)

const p7 = CardSet32(UInt32(1) << 24)
const p8 = CardSet32(UInt32(1) << 25)
const p9 = CardSet32(UInt32(1) << 26)
const pU = CardSet32(UInt32(1) << 27)
const pF = CardSet32(UInt32(1) << 28)
const pK = CardSet32(UInt32(1) << 29)
const pT = CardSet32(UInt32(1) << 30)
const pA = CardSet32(UInt32(1) << 31)

const anycard = xX = 🌠 = CardSet32(0xFFFFFFFF)
const nocard = ⬜ =CardSet32(0x00000000)

const deck = Dict([
    t7 => ("t7", "🎃 7"), t8 => ("t8", "🎃 8"), t9 => ("t9", "🎃 9"), tU => ("tU", "🎃 U"), tF => ("tF", "🎃 F"), tK => ("tK", "🎃 K"), tT => ("tT", "🎃 T"), tA => ("tA", "🎃 A"),
    z7 => ("z7", "🍃 7"), z8 => ("z8", "🍃 8"), z9 => ("z9", "🍃 9"), zU => ("zU", "🍃 U"), zF => ("zF", "🍃 F"), zK => ("zK", "🍃 K"), zT => ("zT", "🍃 T"), zA => ("zA", "🍃 A"),
    m7 => ("m7", "🌰 7"), m8 => ("m8", "🌰 8"), m9 => ("m9", "🌰 9"), mU => ("mU", "🌰 U"), mF => ("mF", "🌰 F"), mK => ("mK", "🌰 K"), mT => ("mT", "🌰 T"), mA => ("mA", "🌰 A"),
    p7 => ("p7", "❤️️ ️️7"), p8 => ("p8", "❤️️ ️️8"), p9 => ("p9", "❤️️ ️️9"), pU => ("pU", "❤️️ ️️U"), pF => ("pF", "❤️️️️ ️️F"), pK => ("pK", "❤️️ ️️K"), pT => ("pT", "❤️️ ️️T"), pA => ("pA", "❤️️ ️️A")])


function print(io::IO, cs::CardSet32, shortForm=true)
    if isempty(cs) return end

    if shortForm
        currentSuit = notrump
        for card in cs
            suit, face = SuitFace(card)
            if suit == currentSuit 
                print(io, faceProperties[face][end])
            else
                print(io, deck[card][1])
                currentSuit = suit
            end
        end
    else    
        for card in cs
          print(io, deck[card][2], " ")
        end
    end
end

function print(io::IO, cs::Vector{CardSet32}, shortForm=true)
    for crd in cs
      print(io, crd, shortForm); println()
    end
end

display(cs::CardSet32) = print(STDOUT, cs, false)
display(cs::Vector{CardSet32}) = print(STDOUT, cs, false)

typealias Suit CardSet32
    const t = union(t7,t8,t9,tU,tF,tK,tT,tA) #Tök
    const z = union(z7,z8,z9,zU,zF,zK,zT,zA) #Zöld
    const m = union(m7,m8,m9,mU,mF,mK,mT,mA) #Makk
    const p = union(p7,p8,p9,pU,pF,pK,pT,pA) #Piros
    const nosuit = notrump = CardSet32() #Szín nélküli (ászkirályos) vagy még nem tudjuk (pl. hátulról bemondott négy tízesnélÖ
    const anySuit = union(t, z, m, p) #any
    const a = b = c = d = CardSet32() #undefined... yet

const suitProperties = Dict([
    (t, (["Tök", "tok", "🎃", "t"], 3)), #Halloween-kor TOK = 7 :)
    (z, (["Zöld", "zold", "🍃", "z"], 4)),
    (m, (["Makk", "🌰", "m"], 5)),
    (p, (["Piros", "❤️️", "p"], 6)), 
    (notrump, (["Színtelen", "notrump", "sz", "n"], 0)),

    ('t', t),
    ('z', z),
    ('m', m),
    ('p', p),
    ('n', notrump),
    ('x', anySuit),
    ('a', a),
    ('b', b),
    ('c', c),
    ('d', d),
    ]) 

typealias Face CardSet32
    const _7 = union(t7, z7, m7, p7) #hetes
    const _8 = union(t8, z8, m8, p8) #nyolcas
    const _9 = union(t9, z9, m9, p9) #kilences
    const U  = union(tU, zU, mU, pU) #alsó
    const F  = union(tF, zF, mF, pF) #felső
    const K  = union(tK, zK, mK, pK) #király
    const T  = union(tT, zT, mT, pT) #tízes
    const A  = union(tA, zA, mA, pA) #ász
    const AT = union(T, A)
    const X  = union(_7, _8, _9, U, F, K, T, A) #barmelyik
    const Y  = union(_7, _8, _9, U, F, K) #kicsi
    const N  = union(_9, U, F, K)   #nem fontos
const faceProperties = Dict(
    _7 => ["Hetes", "7"],
    _8 => ["Nyolcas", "8"],
    _9 => ["Kilences", "9"],
    U => ["Alsó", "U"],
    F => ["Felső", "F"],
    K => ["Király", "K"],
    T => ["Tízes", "T"],
    A => ["Ász", "A"],

    '7' => _7,
    '8' => _8,
    '9' => _9,
    'U' => U,
    'F' => F,
    'K' => K,
    'T' => T,
    'A' => A,
) 

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
suitof(card::Card) = suitFace[card][1]
faceof(card::Card) = suitFace[card][2]
# Card(suit::Suit, face::Face) = suitFace[(suit, face)]
Card(suit::Suit, face::Face) = intersect(suit, face)

#compare two cards using the trump suit
@memoize Dict function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    else
        face1 = UInt64(face1.cs) #to make sure the <<= will not overflow
        face2 = UInt64(face2.cs) 
        if trump == notrump #szintelen jateknal a tizes alulra megy, a kilences es az also koze
            if UInt64(_9.cs) < face1 != T face1 <<= 4 end #UFK a T fole, A meg feljebb
            if UInt64(_9.cs) < face2 != T face2 <<= 4 end #UFK a T fole, A meg feljebb
        end
        return face1 > face2 #MSBs are larger
    end
end

#TODO: trumping is a mess - rewrite
#support structure for trumping
largerThan = Dict{Tuple{Card, Suit}, CardSet32}()
for (card1, s1) in deck
    for (card2, s2) in deck
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
    if length(cards) <= 1 return cards end
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

@memoize Dict function smallestCard(cards::CardSet32, trump::Suit, suit::Suit=trump) #TODO add currentSuit handling
    if length(cards) <= 1 return cards end
    card = last(cards)
    if length(whichTrumps(cards, card, trump)) == length(cards) - 1 #trumped by all
        return card
    else
        return smallestCard(cards - card, trump) #TODO only works for sameSuit and trump
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

@memoize Dict function trumpsNone(card1::Card, cards::CardSet32, trump::Suit) 
    for card in cards
        if trumps(card1, card, trump) return false end
    end
    return true #I trumped no card
    # isempty(intersect(cards, largerThan[(card1, trump)])) #problem: suit (mA does not trump zT if trump is p)
end

#Bemondasok
# abban a sorrendben, ahogy egymashoz fuzik oket (ulti-repulo-40_100-negyAsz-durchmars)
typealias AlapBemondas UInt8
    semmi = UInt8(0) #amig nincs semmi
    ulti = UInt8(1)
    repulo = UInt8(2)
    negyvenSzaz = UInt8(3)
    huszSzaz = UInt8(4)
    negyAsz = UInt8(5)
    durchmars = UInt8(6)
    redurchmars = UInt8(7)
    parti = passz = UInt8(8)
    betli = UInt8(9)
    rebetli = UInt8(10)
    negyTizes = UInt8(11)
    csendesUlti = UInt8(12)
    csendesDuri = UInt8(13)
    
#Bemondasok erteke es nevei (elso nev lesz kiirva)
#TODO: value -> (licit, max, min)
const alapBemondasProperties = Dict([
  (semmi,       (0, ["", "semmi", ""])),
  (ulti,        (4, ["Ulti", "ultimo", "Ult"])),
  (repulo,      (4, ["Repülő", "repulo", "Rep"], )),
  (negyvenSzaz, (4, ["40-100", "40 100", "40_100", "negyvenSzaz", "negyvenSzáz", "Negyven Szaz", "Negyven Száz", "40s"])),
  (huszSzaz,    (8, ["20-100", "20 100", "20_100", "huszSzaz", "húszSzáz", "Husz Szaz", "Húsz Száz", "20s"])),
  (negyAsz,     (4, ["4 Ász", "4 Asz", "negyAsz", "NégyÁsz", "Negy Asz", "Négy Ász", "4A"])),
  (durchmars,   (6, ["Durchmars", "Dur"])),
  (redurchmars, (12, ["Terített Durchmars", "redurchmars", "TDur"])),
  (parti,       (1, ["Parti", "Passz", "Par"])),
  (betli,       (30, ["Betli", "Bet"])), #mert szintelen, nincs szorzo
  (rebetli,     (20, ["Terített Betli", "rebetli", "TBet"])),
  (negyTizes,   (55, ["4 Tízes", "4 Tizes", "negyTizes", "NégyTízes", "Negy Tizes", "Négy Tízes", "4T"])),
])

#Modosito szorzok elolrol bemondott vagy ramondott bemondasokra
typealias Modosito UInt8
    elolrol =  UInt8(4)
    ramondva = UInt8(2)
    hatulrol = UInt8(1)

const modositoProperties = Dict([
  (elolrol,  ["Elölről",  "Elolrol",  "E"]),
  (ramondva, ["Rámondva", "ramondva", "R"]),
  (hatulrol, ["Hátulról", "hatulrol", "H"]),
])


typealias Kontra UInt8
    KE = UInt8(4)
    KH = UInt8(2)

const kontraProperties = Dict([
  (KE, ["Elölről kontra",  "KE"]),
  (KH, ["Hátulról kontra", "KH"]),
])
typealias Kontrak Array{Kontra, 1} #pl. Kontrak([KE,KE,KH]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x

# function show(Kontrak) end #kiirja a kontra, re, szub, mord, stb. -t

#Egy alapbemondas modositokkal
immutable ContractElement
    modosito::Modosito
    bem::AlapBemondas
    kon::Kontrak
    val::Number
 end

function print(io::IO, ce::ContractElement, shortFormat::Bool=true)
    print(io, 
        shortFormat ? modositoProperties[ce.modosito][end] : modositoProperties[ce.modosito][1] * " ",
        shortFormat ? alapBemondasProperties[ce.bem][2][end] : alapBemondasProperties[ce.bem][2][1] * " ")
        
    for k in ce.kon
        print(io, kontraProperties[k][2])
    end
end

display(ce::ContractElement) = print(STDOUT, ce, false)

#A bemondas
immutable Contract
    suit::Suit
    contracts::Array{ContractElement}
    totalvalue::Number
end

const nocontract = Contract(notrump,[],0)
isequal(c1::Contract, c2::Contract) = isequal(c1.suit, c2.suit) && isequal(c1.contracts, c2.contracts)
==(c1::Contract, c2::Contract) = isequal(c1::Contract, c2::Contract)

function copy(contract::Contract)
    #TODO: deep copy of contracts? - maybe not for performance reasons
    Contract(contract.suit, contract.contracts, contract.totalvalue)
end

@memoize function isUlti(contract::Contract)
    for ce in contract.contracts
        if ce.bem == ulti
            return true
        end
    end
    return false
end

@memoize function isRepulo(contract::Contract)
    for ce in contract.contracts
        if ce.bem == repulo
            return true
        end
    end
    return false
end

@memoize isUltiRepulo(contract::Contract) = isUlti(contract) && isRepulo(contract)

contractValues = Dict{Tuple{Suit,AlapBemondas,Modosito}, Int}()
#TODO mit lehet elolrol hatulrol es ramondva bemondani
#szines bemondasok
for suit in [t, z, m, p]
    for bem in [parti, negyvenSzaz, ulti, repulo, negyAsz, durchmars, huszSzaz, rebetli, redurchmars]
        for honnan in [elolrol, ramondva, hatulrol]
            contractValues[(suit, bem, honnan)] = UInt8(honnan) * suitProperties[suit][2] * alapBemondasProperties[bem][1]
        end
    end
end
#negy tizes
for suit in [t,z,m,p]
    contractValues[(suit, negyTizes, ramondva)] = 192
    contractValues[(suit, negyTizes, hatulrol)] = 55
end
#szintelen bemondasok
contractValues[(notrump, negyTizes, hatulrol)] = 55 #TODO: has to be declared and set later
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
function print(io::IO, contract::Contract, shortFormat::Bool=true)

    if contract == nocontract return "" end

    if !shortFormat
        print(io, "Bemondás: ", suitProperties[contract.suit][1][1], " ")
    else
        print(io, suitProperties[contract.suit][1][end])
    end

    for ce in contract.contracts
        print(io, ce, shortFormat)
    end
end

display(contract::Contract) = print(STDOUT, contract, false)

function parseContract(contract::String)
    regexp = r"(t|z|m|p|a|b|c|d|s|nt|sz)? ( ([Ee]|[Rr]|[Hh]|Elolrol|Ramondva|Hatulrol)? (Passz|Parti|semmi|P|Ult|Rep|4A|Dur|Bet|40s|20s|4T|Tbet|Tdur|Terb|Terd)? (KE*KH*|ERK|ERe|HRK|HRe|ESK|ESub|HSK|HSub|EMK|EMord|HMK|HMord)? )*"
end

##############
#Tests
##############
