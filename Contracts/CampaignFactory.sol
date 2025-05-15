// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CampaignFactory {
    address[] public deployedCampaigns;
    
    event CampaignCreated(address campaignAddress);

function createCampaign(
    address influencerWallet,
    uint maxPayout,
    uint payoutRate,
    uint metricThreshold,

) public payable returns (address) {
    require(msg.value >= maxPayout, "Must send funds for payout");

    // Deploys a fresh contract for each campaign
    InfluencerPayout newCampaign = (new InfluencerPayout){value: msg.value}(
        msg.sender, 
        influencerWallet,
        maxPayout,
        payoutRate,
        metricThreshold,
        
    );

    deployedCampaigns.push(address(newCampaign));
    emit CampaignCreated(address(newCampaign));

    return address(newCampaign);
}

}

contract InfluencerPayout {
    address public businessWallet;
    address public influencerWallet;

    uint public maxPayout;
    uint public payoutRate;
    uint public metricThreshold;
    string public metricType;

    bool public payoutFinalized;

    event PayoutCompleted(address indexed influencer, uint amount);
    event RefundIssued(address indexed business, uint amount);

    constructor(
        address _businessWallet,
        address _influencerWallet,
        uint _maxPayout,
        uint _payoutRate,
        uint _metricThreshold,
        string memory _metricType
    ) payable {
        businessWallet = _businessWallet;
        influencerWallet = _influencerWallet;
        maxPayout = _maxPayout;
        payoutRate = _payoutRate;
        metricThreshold = _metricThreshold;
        metricType = _metricType;
    }

    receive() external payable {}

   
    function finalizePayout(uint totalConversions) public {
        require(!payoutFinalized, "Payout already finalized");
        payoutFinalized = true;

        // Calculate payout: (totalConversions / metricThreshold) * payoutRate
        uint calculatedPayout = (totalConversions / metricThreshold) * payoutRate;

        // Cap payout to maxPayout
        if (calculatedPayout > maxPayout) {
            calculatedPayout = maxPayout;
        }

        // Ensure contract has enough balance
        uint contractBalance = address(this).balance;
        if (calculatedPayout > contractBalance) {
            calculatedPayout = contractBalance;
        }

        // Transfer calculated payout to influencer
        payable(influencerWallet).transfer(calculatedPayout);
        emit PayoutCompleted(influencerWallet, calculatedPayout);

        // Refund any remaining funds back to the business
        uint remaining = address(this).balance;
        if (remaining > 0) {
            payable(businessWallet).transfer(remaining);
            emit RefundIssued(businessWallet, remaining);
        }
    }
}
