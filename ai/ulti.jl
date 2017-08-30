
# module Ulti
include("ai.jl")

#TODO: separate UI/UX from engine - getLicit() -> licit(bemondas), etc.
#TODO: parallel console and WebSocket implementation (interactive = true/false)
#TODO: websocketd? Julia websockets?

#TODO UI: auto-40-20 - if clicked, no need to click it every time.
#TODO: separate state types by *, such as S*..., L*..., G*... sent to parseState

##############
#Engine runtime loop
##############

#RNG
SEED = 0
rng = MersenneTwister(SEED)
# rng = RandomDevice() #truly random

function getLicit(player::Player, currentLicit::Contract)
    while true
        try
            lct = chomp(readline())
            contract = parseContract(lct, player, currentLicit)

            if contract != nocontract && contract.totalvalue <= currentLicit.totalvalue
                println("Contract value must be higher than the current one $(currentLicit.totalvalue) > $(contract.totalvalue)")
            # elseif #TODO: kontrazni csak az eddigi bemondast lehet

            else
                return contract
            end
        catch e
            if isa(e, InterruptException) || isa(e, SystemError)
                throw(e)
            end
            println("unable to parse, please try again")
        end

    end
end

function mainLoop()
    println("Enter the number of players (default: 3)")
    numberOfPlayers = 3
    try
      numberOfPlayers = parse(Int64, readline())
    catch ArgumentError
    end

    println("Enter player names separated by comma. Default: Alfa, Béla, Gamma, ...")
    try
      nameStrings = readline() |> x -> chomp(x) |> x -> split(x, ',')
      assert(length(nameStrings) == numberOfPlayers)

      for (i, name) in enumerate(nameStrings)
        playerNames[Player(i)] = name
      end
    catch
        #NOP
    end

    #create sessionState
    session = sessionState(Vector{Tuple{Player, Int}}())
    firstplayer = 0x01 #elso kezd eloszor

    while true
        #Create licitState
        licitState = LicitState(numberOfPlayers, firstplayer)
        dealInitialCards!(licitState)

        #Licit phase
        while true
            print(STDOUT, licitState, false)
            lct = getLicit(licitState.currentPlayer, licitState.contract)
            licitState = licit!(licitState, lct)
            #check if licit is over
            #either no contract for a round (korpassz)
            #or no contract since current player made one
            if (length(licitState.contractHistory) == 0 &&
                    licitState.currentPlayer == licitState.firstPlayer)
                #korpassz, uj osztas
                break
            elseif  (length(licitState.contractHistory) > 0 && 
                    licitState.contractHistory[end].felvevo == licitState.currentPlayer)    
                #create gameState
                gameState = startGamePhase(licitState)
                print(STDOUT, gameState, false)
                #Lejatszas
                # while true

                # end
                break
            end
        end

        #Update scores and history

        #Rotate firstplayer
        firstplayer = nextPlayer(firstplayer, numberOfPlayers)
    end
end

##############
#Tests
##############

function testGame()
    g = GameState(
        #TODO BUG kontra parti nem jelenik meg
      Contract(0x01, p, [ContractElement(elolrol, ulti, Kontrak(), 96), ContractElement(elolrol, parti, Kontrak(pX, [KH]), 48)], 144), #elolrol piros ulti (+ passz) 
      (
        PlayerState(
          Player(1),
          CardSet([pA,pT,pK,pU,p7, mK,mU,m8, tT, z9]), #felvevo lapja
          CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
        ),
        PlayerState(
          Player(2),
          CardSet([pF,p9,p8, mA,mF,m7, zK, zF, z7, tF]), #2. jatekos lapja
          CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
        ),
        PlayerState(
          Player(3),
          CardSet([mT,m9, zA,zT,zU,z8, tA,tK,t8,t7 ]), #3. jatekos lapja
          CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
        )
      ),
      CardSet(), #pakli ures (kiosztva)
      CardSet(), #asztal ures
      CardSet([t9, tU]), #talon
      p1 #current player
    )

    # g=newState(g, rand(rng, validMoves(g)))
    # alfabeta(g, -1, typemin(Int), typemax(Int))
    # alfabeta(g, -1, -g.contract.totalvalue, g.contract.totalvalue)
    # end #module
end
