// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address payable public admin;
    address payable public winner;
    uint256 public deadline;
    uint256 public prizePoolInTX;
    uint256 public totalEntries;

    constructor(uint256 _deadline) {
        admin = payable(msg.sender);
        deadline = _deadline;
    }

    function enterRaffle() public payable {
        require(block.timestamp <= deadline, "Raffle deadline has passed");
        require(msg.value > 0, "Must enter with some TX tokens");

        totalEntries++;
        prizePoolInTX += msg.value;
    }

    function selectWinner() public {
        require(block.timestamp > deadline, "Raffle deadline has not passed yet");
        require(winner == address(0), "Winner already selected");

        winner = payable(randomWinner());

        // Emit WinnerSelected event
        emit WinnerSelected(winner);

        // Optionally, implement additional functionality after winner selection
    }

    function randomWinner() private view returns (address) {
        // ... implement your random winner selection logic here
    }

    function resetRaffleForNewRound(uint256 _newDeadline) public {
        require(msg.sender == admin && winner != address(0), "Only admin can reset after winner chosen");

        // Transfer any unclaimed TX tokens to admin (if applicable)
        // ...

        // Reset state variables for the new round
        deadline = _newDeadline;
        prizePoolInTX = 0;
        totalEntries = 0;
        winner = payable(address(0));

        // Optionally, reset individual user entries:
        // ...
    }

    event WinnerSelected(address winner);
}