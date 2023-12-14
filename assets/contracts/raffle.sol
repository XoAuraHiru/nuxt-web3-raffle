// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Raffle {
    // Replace these values with your actual configurations:
    address payable public admin; // Address of the admin wallet
    uint256 public ticketPriceInTX; // Number of TX tokens per raffle ticket
    uint256 public deadline; // Timestamp in seconds until raffle closes
    address public VRF_COORDINATOR; // Chainlink VRF Coordinator address for BSC testnet
    bytes32 public keyHash; // Hash associated with randomness level for VRF
    uint64 public subscriptionId; // Your Chainlink VRF v2 subscription ID
    uint16 public requestConfirmations; // Minimum confirmations for VRF requests
    uint32 public callbackGasLimit; // Maximum gas limit for processing VRF random numbers
    address public TX_TOKEN; // Token address for raffle tickets
    uint32 public numWords;

    // Mapping of user addresses to raffle entry count
    mapping(address => uint256) public entries;

    // Total number of raffle entries
    uint256 public totalEntries;

    // Current prize pool in TX tokens
    uint256 public prizePoolInTX;

    // Winner address
    address payable public winner;

    // Events for ticket purchase, winner selection, and claim
    event TicketPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 entries
    );
    event WinnerSelected(address indexed winner);
    event EntriesClaimed(address indexed user, uint256 amount);
    event RaffleResetForNewRound(uint256 newDeadline);

    // Constructor with deployment parameters
    constructor(
        address payable _admin,
        uint256 _ticketPriceInTX,
        uint256 _deadline,
        address _VRF_COORDINATOR,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        address _TX_TOKEN,
        uint32 _numWords
    ) {
        admin = payable(0x0837fc6A3056470E2F280dab4511aC3c4e6dacd7);
        ticketPriceInTX = 1000 * 10**18;
        deadline = block.timestamp + 7 * 24 * 60 * 60;
        VRF_COORDINATOR = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
        keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;
        subscriptionId = 3259;
        requestConfirmations = 3;
        callbackGasLimit = 200000;
        prizePoolInTX = 0; // Initialize prize pool to zero
        numWords = 1;
    }

    // Buy raffle tickets with TX tokens
    function buyRaffleTicket(uint256 txAmount) public {
        require(block.timestamp < deadline, "Raffle closed");
        require(txAmount >= ticketPriceInTX, "Insufficient TX tokens");

        // Calculate prize and admin fee
        uint256 prize = (txAmount * 75) / 100;
        uint256 fee = (txAmount * 25) / 100;

        // Update prize pool and admin wallet
        prizePoolInTX += prize;
        admin.transfer(fee);

        // Update user's raffle entry count and total entries
        entries[msg.sender] += txAmount;
        totalEntries += txAmount;

        // Transfer TX tokens from user to contract
        IERC20(TX_TOKEN).transferFrom(msg.sender, address(this), txAmount);

        emit TicketPurchased(msg.sender, txAmount, txAmount);
    }

    // Select winner randomly using VRF
    function selectWinner() public payable {
        require(
            msg.sender == admin && block.timestamp > deadline,
            "Only admin can select winner after deadline"
        );

        // Request random numbers from VRF coordinator
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(
            VRF_COORDINATOR
        );
        coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        ); // Optional empty userSeed
    }

    // Process VRF callback and choose winner
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal virtual {
        require(winner == address(0), "Winner already selected");

        uint256 randomNumber = randomWords[0];
        uint256 winningEntry = randomNumber % totalEntries;
        winner = payable(entries[winningEntry]);

        // Transfer entire prize pool to winner
        IERC20(TX_TOKEN).transfer(winner, prizePoolInTX);
        prizePoolInTX = 0;

        // Emit WinnerSelected event
        emit WinnerSelected(winner);
    }

    function resetRaffleForNewRound(uint256 _newDeadline) public {
        require(
            msg.sender == admin && winner != address(0),
            "Only admin can reset after winner chosen"
        );

        // Transfer any unclaimed TX tokens to admin (if applicable)
        // ...

        // Reset state variables for the new round
        deadline = _newDeadline;
        prizePoolInTX = 0;
        totalEntries = 0;
        winner = payable(address(0));

        // Optionally, reset individual user entries:
        // ...

        emit RaffleResetForNewRound(_newDeadline);
    }

    function claimRaffleEntries() public {
        require(winner != address(0), "Winner not yet selected");
        require(entries[msg.sender] > 0, "No raffle entries to claim");

        uint256 claimableTokens = entries[msg.sender];

        // Reset user's entry count
        entries[msg.sender] = 0;

        // Transfer claimable TX tokens to user
        IERC20(TX_TOKEN).transfer(msg.sender, claimableTokens);

        emit EntriesClaimed(msg.sender, claimableTokens);
    }
}
