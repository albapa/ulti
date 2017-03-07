
##############
#Game Engine
##############

#The 32 Cards
typealias Card Int #could be set to UInt8/Int to fit in memory and/or speed
const t7=Card(0)
const t8=Card(1)
const t9=Card(2)
const ta=Card(3)
const tf=Card(4)
const tk=Card(5)
const tt=Card(6)
const ts=Card(7)
const z7=Card(8)
const z8=Card(9)
const z9=Card(10)
const za=Card(11)
const zf=Card(12)
const zk=Card(13)
const zt=Card(14)
const zs=Card(15)
const m7=Card(16)
const m8=Card(17)
const m9=Card(18)
const ma=Card(19)
const mf=Card(20)
const mk=Card(21)
const mt=Card(22)
const ms=Card(23)
const p7=Card(24)
const p8=Card(25)
const p9=Card(26)
const pa=Card(27)
const pf=Card(28)
const pk=Card(29)
const pt=Card(30)
const ps=Card(31)
#@enum CARD T7=0 T8=1 T9=2 TA=3 TF=4 TK=5 TT=6 TS=7 Z7=8 Z8=9 Z9=10 ZA=11 ZF=12 ZK=13 ZT=14 ZS=15 M7=16 M8=17 M9=18 MA=19 MF=20 MK=21 MT=22 MS=23 P7=24 P8=25 P9=26 PA=27 PF=28 PK=29 PT=30 PS=31 

typealias Suit Int
const t=Suit(0)
const z=Suit(1)
const m=Suit(2)
const p=Suit(3)
const notrump=Suit(4)
#@enum SUIT T=0 Z=1 M=2 P=3 NOTRUMP=4

typealias Face Int
const f7=Face(0)
const f8=Face(1)
const f9=Face(2)
const fa=Face(3)
const ff=Face(4)
const fk=Face(5)
const ft=Face(6)
const fs=Face(7)
#@enum FACE _7=0 _8=1 _9=2 A=3 F=4 K=5 _10=6 S=7

SuitFace(card::Card) = Suit(div(card, Card(8))), Face(mod(card, Card(8)))
SuitFace(suit::Suit, face::Face) = Card(Card(8) * suit + face)

function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    elseif trump != notrump #szines jateknal a sorrend pontos
        face1 > face2
    else #szintelen jateknal a tizes alulra megy, a kilences es az also koze
        if face1 == ft face1 = 2.5 end
        if face2 == ft face2 = 2.5 end
        return face1 > face2
    end
end

function trumps(card1::Card, card2::Card, card3::Card, trump::Suit)

end

#A bemondas
type Contract
end

#a set of cards
#implemented as a memoised set of sets to avoid duplication
#Note: could be implemented as a full-blown class if needed
typealias CardSet IntSet

type GameState
    contract::Contract  #mi a bemondas

    deck::CardSet       # leosztatlan pakli
    table::CardSet      # asztal kozepe
    talon::CardSet      # talon
    p1_hand::CardSet 
    p1_discard::CardSet 
    p2_hand::CardSet 
    p2_discard::CardSet 
    p3_hand::CardSet 
    p3_discard::CardSet 

    function GameState()
    function parse()
        #example: ('piros nsz ulti', 't7 t8 p9 pa pf ps pk', 'z8 z9', ... <<<all 8 sets>>>)

        #checks: are all cards accounted for?
        #nobody has the right number of cards
    end

    function move!(Card card, CardSet from, CardSet to)
        setdiff!(from, [card])
        union!(to, [card])
    end

    #this is the main (recursive loop for the minimax evaluation)
    #note: may be implemented partially on the client side in javascript
    function score(CardSet from, CardSet to)

        #if all cards are played ...
    end

    #efficiend storage for game state:
    #list of 32 cardsets, 3 bits each -> 96 bits + bemondas a #tablazatbol
    function compact() 
    function decompact()
end


##############
#AI
##############

type MiniMaxTree
#tree for evaluation


