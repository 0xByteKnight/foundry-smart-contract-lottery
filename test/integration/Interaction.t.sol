// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract RaffleIntegrationTest is Test {
    /*//////////////////////////////////////////////////////////////
                           State Variables
    //////////////////////////////////////////////////////////////*/
    Raffle raffle;
    HelperConfig helperConfig;
    VRFCoordinatorV2_5Mock vrfCoordinator;
    LinkToken linkToken;
    uint256 subscriptionId;

    /*//////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier SubscriptionCreated() {
        CreateSubscription createSubscription = new CreateSubscription();
        (subscriptionId,) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator, helperConfig.getConfig().account
        );
        _;
    }

    modifier SubscriptionFunded() {
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().link,
            helperConfig.getConfig().account
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              Functions
    //////////////////////////////////////////////////////////////*/

    function setUp() external {
        // Deploy mocks
        vrfCoordinator = new VRFCoordinatorV2_5Mock(0.25 ether, 1e9, 4e15);
        linkToken = new LinkToken();

        // Deploy helper configuration
        helperConfig = new HelperConfig();

        // Deploy raffle contract
        HelperConfig.NetworkConfig memory config = helperConfig.getOrCreateAnvilEthConfig();
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            address(vrfCoordinator),
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
    }

    function testDeployContract() public {
        // Arrange
        DeployRaffle deployRaffle = new DeployRaffle();

        // Act
        (raffle, helperConfig) = deployRaffle.run();

        // Assert
        assert(raffle.getSubscriptionId() != 0);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        assert(config.vrfCoordinator != address(0));
        assert(
            VRFCoordinatorV2_5Mock(config.vrfCoordinator).consumerIsAdded(raffle.getSubscriptionId(), address(raffle))
        );
    }

    /*//////////////////////////////////////////////////////////////
                       CreateSubscription Tests
    //////////////////////////////////////////////////////////////*/

    function testCreateSubscriptionUsingConfig() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (subscriptionId,) = createSubscription.createSubscriptionUsingConfig();

        // Assert
        assert(subscriptionId != 0);
    }

    function testCreateSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (subscriptionId,) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator, helperConfig.getConfig().account
        );

        // Assert
        assert(subscriptionId != 0);
    }

    /*//////////////////////////////////////////////////////////////
                        FundSubscription Tests
    //////////////////////////////////////////////////////////////*/

    function testFundSubscription() public SubscriptionCreated {
        // Arrange
        FundSubscription fundSubscription = new FundSubscription();

        // Act
        fundSubscription.fundSubscription(
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().link,
            helperConfig.getConfig().account
        );

        // Assert
        (uint256 balance,,,,) =
            VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator).getSubscription(subscriptionId);
        assert(balance > 0);
    }

    /*//////////////////////////////////////////////////////////////
                          AddConsumer Tests
    //////////////////////////////////////////////////////////////*/



    function testAddConsumer() public SubscriptionCreated SubscriptionFunded {
        // Arrange
        AddConsumer addConsumer = new AddConsumer();

        // Act
        addConsumer.addConsumer(
            address(raffle), helperConfig.getConfig().vrfCoordinator, subscriptionId, helperConfig.getConfig().account
        );

        // Assert
        assert(
            VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator).consumerIsAdded(
                subscriptionId, address(raffle)
            )
        );
    }

    function testRaffleWorkflow() public SubscriptionCreated SubscriptionFunded {
        // Arrange
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle), helperConfig.getConfig().vrfCoordinator, subscriptionId, helperConfig.getConfig().account
        );

        // Act: Enter the raffle
        vm.deal(address(1), 1 ether);
        vm.startPrank(address(1));
        raffle.enterRaffle{value: helperConfig.getConfig().entranceFee}();
        vm.stopPrank();

        // Assert: Validate player entry
        assertEq(raffle.getRafflePlayers(0), address(1), "Player address should match.");
    }
}
