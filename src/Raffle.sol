// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle contract
 * @author 0xByteKnight
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRF v2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    enum RaffleStates {
        Open,
        Calculating
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // @dev The duration of the lottery in seconds.
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleStates private s_raffleState;

    event NewPlayerEnteredRaffle(address indexed player);
    event WinnerPicked(address indexed Winner);
    event WinnerPrizeTransferred(address indexed Winner, uint256 indexed winnerPrize);
    event RequestedRaffleWinner(uint256 indexed requestId);

    error Raffle__NotEnoughEtherSent();
    error Raffle__UpkeepNotNeeded(uint256 raffleBalance, uint256 playersLength, uint256 raffleState);
    error Raffle__TransferToWinnerFailed();
    error Raffle__RaffleStateNotAllowsToEnter();

    modifier EnsureRaffleOpen() {
        if (s_raffleState != RaffleStates.Open) {
            revert Raffle__RaffleStateNotAllowsToEnter();
        }
        _;
    }

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleStates.Open;
    }

    function enterRaffle() public payable EnsureRaffleOpen {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEtherSent();
        }

        s_players.push(payable(msg.sender));
        emit NewPlayerEnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink nodes will call to see whether it's time to pick a lottery winner.
     * The following should be true in order for upkeepNeeded to be trye:
     * 1. The time interval has passeds between raffle runs.
     * 2. The lotter is open.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription has LINK.
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ingored
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimestamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleStates.Open;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, hex"");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleStates.Calculating;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] calldata randomWords) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;

        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        emit WinnerPicked(s_recentWinner);

        s_raffleState = RaffleStates.Open;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferToWinnerFailed();
        }
        emit WinnerPrizeTransferred(s_recentWinner, address(this).balance);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleStates) {
        return s_raffleState;
    }

    function getRafflePlayers(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getSubscriptionId() external view returns (uint256) {
        return i_subscriptionId;
    }
}
