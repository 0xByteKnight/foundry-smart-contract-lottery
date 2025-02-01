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
    /*//////////////////////////////////////////////////////////////
                          Type Declarations
    //////////////////////////////////////////////////////////////*/
    enum RaffleStates {
        Open,
        Calculating
    }

    /*//////////////////////////////////////////////////////////////
                           State Variables
    //////////////////////////////////////////////////////////////*/
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

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event NewPlayerEnteredRaffle(address indexed player);
    event WinnerPicked(address indexed Winner);
    event WinnerPrizeTransferred(address indexed Winner, uint256 indexed winnerPrize);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /*//////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/
    error Raffle__NotEnoughEtherSent();
    error Raffle__UpkeepNotNeeded(uint256 raffleBalance, uint256 playersLength, uint256 raffleState);
    error Raffle__TransferToWinnerFailed();
    error Raffle__RaffleStateNotAllowsToEnter();

    /*//////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier EnsureRaffleOpen() {
        if (s_raffleState != RaffleStates.Open) {
            revert Raffle__RaffleStateNotAllowsToEnter();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             Functions
    //////////////////////////////////////////////////////////////*/
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

    /*//////////////////////////////////////////////////////////////
                          External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Triggers the process of selecting a raffle winner.
     * @dev Checks if the raffle conditions are met and requests a random number from Chainlink VRF.
     * If conditions are met, the raffle state is updated, and an event is emitted.
     * performData parameter included for compatibility with Chainlink Automation.
     */
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

    /*//////////////////////////////////////////////////////////////
                           Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows a user to enter the raffle by sending the required entrance fee.
     * @dev Verifies that the raffle is open and the sent ETH amount is sufficient.
     * Adds the sender to the list of participants and emits an event.
     */
    function enterRaffle() public payable EnsureRaffleOpen {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEtherSent();
        }

        s_players.push(payable(msg.sender));
        emit NewPlayerEnteredRaffle(msg.sender);
    }

    /**
     * @notice Checks if the raffle is ready to select a winner.
     * @dev Called by Chainlink Automation to determine if upkeep is needed.
     * Conditions:
     * - Time interval has passed.
     * - Raffle is open.
     * - Contract has ETH balance.
     * - There is at least one participant.
     * @return upkeepNeeded True if upkeep is needed.
     * @return performData Always returns an empty bytes array.
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

    /*//////////////////////////////////////////////////////////////
                          Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Picks a random winner and transfers the prize.
     * @dev Called by Chainlink VRF after a random number is generated.
     * Resets the raffle and sends the contract balance to the winner.
     * requestId Unused parameter included for compatibility with Chainlink VRF.
     * @param randomWords Array containing the generated random number.
     */
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

    /*//////////////////////////////////////////////////////////////
               Public & External View & Pure Functions
    //////////////////////////////////////////////////////////////*/

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
