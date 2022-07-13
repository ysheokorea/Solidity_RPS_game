// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract RPS{
    constructor() payable{}

    enum Hand{
        rock, paper, scissors
    }

    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus{
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Player{
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        PlayerStatus playerStatus;
    }

    struct Game{
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
        uint16 playerNum;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;

    modifier isValidHand(Hand _hand){
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    modifier isPlayer(uint roomNum, address sender){
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    

    function createRoom(Hand _hand) public payable isValidHand(_hand) returns(uint roomNum){
        rooms[roomLen] = Game({
            betAmount : msg.value,
            gameStatus : GameStatus.STATUS_NOT_STARTED,
            originator : Player({
                hand : _hand,
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmount : msg.value
            }),
            taker : Player({
                hand : Hand.rock,
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmount : 0
            }),
            playerNum : 1
        });
        roomNum = roomLen;
        roomLen++;

    }

    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand){
        rooms[roomNum].taker = Player({
            hand : _hand,
            addr : payable(msg.sender),
            playerStatus : PlayerStatus.STATUS_PENDING,
            playerBetAmount : msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        rooms[roomNum].playerNum++;
        compareHands(roomNum);
    }

    function compareHands(uint roomNum) private{
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if(taker == originator){
            // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }else if((taker + 1) % 3 == originator){
            // originator이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }else if((taker + 1) % 3 == originator){
            // originator이 패배한 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        }else{
            // 예외 경우
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    function checkTotalPay(uint roomNum) public view returns(uint roomNumPay){
        return rooms[roomNum].betAmount;
    }

    function checkNumOfPlayer(uint roomNum) public view returns(uint numOfPlayers){
        return rooms[roomNum].playerNum;
    }

    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender){
        // 비긴 경우
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        }else{
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }else{
                // 오류가 발생하는 경우 베팅 금액 환불
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
            rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
        }
    }
}