// SPDX-License-Identifier: Apache2.0
pragma solidity ^0.8.0;

contract CharityDonation{

    // ethereum address of contract owner
    address payable contractOwner;

    // list of charities (by address) this contract supports
    address payable[] private supportedCharities;

    // variable to store total number of donations
    uint private totalDonations;

    // variables to store top donor info
    uint private topDonation;
    address private topDonor;

    // constructor to initialize contract owner, supported charities and init total donations sum
    constructor(address payable[] memory charities) {
        contractOwner = payable(msg.sender);
        supportedCharities = charities;
        totalDonations = 0;
    }

    /// modifier to prerequisite contract onwer only access to some methods
    modifier ownerOnly {
      require(msg.sender == contractOwner);
      _;
    }

    /// define donation event
    event DonationEvent(address donor, uint donationAmount);

    /* Contract level methods */

    /// view function to check if charity input is valid
    function verifyCharityID(uint8 inputCharityID) private view {
        require(inputCharityID >= 0 && inputCharityID < supportedCharities.length, "Input charity ID is invalid");
    }

    /// checks if sender address has sufficient funds to send
    function checkIfFundsExist(uint userBalance, uint amountToSend) private pure {
        require(userBalance >= amountToSend, "Check if user has the amount of ETH specified to send");
    }

    /// checks if current donation is bigger than the previous top one and alters info
    function alterTopDonor(uint currentDonationAmount, uint _topDonation) private {
        if (_topDonation < currentDonationAmount) {
            topDonation = currentDonationAmount;
            topDonor = msg.sender;
        }
    }

    /// increase total donations amount
    function increaseDonationTotal(uint amountDonated) private {
        totalDonations = totalDonations + amountDonated;
    }

    /// sends donation (funds) to charity and destination address and emits a donation event
    function makeTransactions(uint amountToDonate, address payable destinationAddress, uint amountToSend, uint8 charityID) private {
        supportedCharities[charityID].transfer(amountToDonate);
        destinationAddress.transfer(amountToSend);

        // emit donation event when transfers are made
        emit DonationEvent(msg.sender, amountToDonate);
    }


    /* Publicly accessible methods  */

    // variation A that sends 10% as a donation to a selected charity
    function sendFunds(address payable destinationAddress, uint8 charityID) public payable{
        verifyCharityID(charityID);
        checkIfFundsExist(msg.sender.balance, msg.value);

        // donation strategy (10%)
        uint amountToDonate = msg.value / 10;
        uint amountToSend = msg.value - amountToDonate;

        alterTopDonor(amountToDonate, topDonation);

        increaseDonationTotal(amountToDonate);

        makeTransactions(amountToDonate, destinationAddress, amountToSend, charityID);
    }

    // variation B that sends specified donation amount to a selected charity
    function sendFunds(address payable destinationAddress, uint8 charityID, uint amountToDonate) public payable{
        verifyCharityID(charityID);
        checkIfFundsExist(msg.sender.balance, msg.value);
         
        // donation strategy (specific amount)
        require(amountToDonate >= msg.value/100 && amountToDonate <= msg.value/2, "Donation amount must be at least 1% and at most 50% of the amount send");
        uint amountToSend = msg.value - amountToDonate;

        alterTopDonor(amountToDonate, topDonation);

        increaseDonationTotal(amountToDonate);

        makeTransactions(amountToDonate, destinationAddress, amountToSend, charityID);
    }

    // function to view total sum of donations made to all charities
    function getOverallDonationInfo() public view returns (uint) {
        return totalDonations;
    }
    
    /* Methods accesible only from contract owner */

    // Get top donation amount and who made it
    function getTopDonation() public ownerOnly view returns (uint, address) {
        return (topDonation, topDonor);
    }

    // destroy contract and send all funds attached, to the contract owner
    function destroyContract() public ownerOnly {
        selfdestruct(contractOwner);
    }
}