//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a proof of concept network state DAO contract in
 * which users can be part of an online community that has
 * governance based on democratic voting. Users can buy and
 * destroy their DAO citizenships. They can also create ETH
 * fundraising campaigns and contribute to different campaigns.
 * NOTE: Not production ready as buying citizenship needs to be
 * with the DAO's token.
 */

import "./DAOCitizenship.sol";
import "./Ballot.sol";

contract NetworkStateDAO is DAOCitizenship, Ballot {
    // Community name
    string public communityName = "Network State DAO";

    // DAO citizen population
    uint256 public citizens;

    // Struct that contains details of a specific fundraising campaign
    struct Campaign {
        // Campaign name
        string name;
        // Campaign creator address
        address creator;
        // Campaign ETH amount goal
        uint256 goal;
        // Total amount contributed
        uint256 contributed;
        // Timestamp of start of campaign
        uint256 startAt;
        // Timestamp of end of campaign
        uint256 endAt;
        // True if campaign goal is reached and creator claims ETH
        bool claimed;
    }

    // Campaign ID that increments by one every time a new campaign is created
    uint256 public campaignCount;
    // Mapping of campaign ID to Campaign
    mapping(uint256 => Campaign) public campaigns;
    // Mapping of campaign ID to user address that maps to amount contributed
    mapping(uint256 => mapping(address => uint256)) public contributedAmount;

    // Events
    event CitizenAdded(address citizen, uint256 citizenId);

    event CitizenLost(address citizen, uint256 citizenId);

    event FundraiserCampaignCreated(
        string name,
        address indexed creator,
        uint256 goal,
        uint256 startAt,
        uint256 endAt
    );

    event FundraiserCampaignCanceled(string name, address indexed creator);

    event ContributedToCampaign(
        string name,
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );

    event RetrievedFromCampaign(
        string name,
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );

    event ClaimedFromCampaign(
        string name,
        uint256 indexed campaignId,
        address indexed creator
    );

    event RefundedFromCampaign(
        string name,
        uint256 indexed campaignId,
        address indexed contributor
    );

    // Allows contract to receive ether
    receive() external payable {}

    // Function to obtain DAO citizenship
    // NOTE: Not complete as DAO token payment and any other requirements can be added
    function buyCitizenship() public {
        citizens += 1;

        DAOCitizenship._mint(msg.sender, citizens);

        emit CitizenAdded(msg.sender, citizens);
    }

    // Function to destroy DAO citizenship
    function destroyCitizenship(uint256 _citizenId) public {
        address citizen = DAOCitizenship.ownerOf(_citizenId);

        require(citizen == msg.sender, "Can only destroy your own citizenship");

        citizens -= 1;

        DAOCitizenship._burn(_citizenId);

        emit CitizenLost(msg.sender, _citizenId);
    }

    // Function to create a fundraiser campaign for citizens to participate in
    function createFundraiserCampaign(
        string memory _name,
        uint256 _goal,
        uint256 _startAt,
        uint256 _endAt
    ) public {
        require(
            DAOCitizenship.balanceOf(msg.sender) > 0,
            "Need citizenship to start fundraiser campaign"
        );
        // Assuming 1 block per 15 seconds (4 * 60 * 24 * 183)
        require(
            (DAOCitizenship.registrationDate(msg.sender) + 1054080) <
                block.timestamp,
            "Need to be a citizen for at least half a year"
        );

        require(_startAt >= block.timestamp, "Start time < Current time");
        require(_endAt >= _startAt, "End time < Start time");
        // Campaign max time limit is 90 days (4 * 60 * 24 * 90)
        require(
            _endAt <= block.timestamp + 518400,
            "Max fundraiser campaign time is 90 days"
        );

        campaignCount += 1;

        campaigns[campaignCount] = Campaign({
            name: _name,
            creator: msg.sender,
            goal: _goal,
            contributed: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit FundraiserCampaignCreated(
            _name,
            msg.sender,
            _goal,
            _startAt,
            _endAt
        );
    }

    // Function for fundraiser campaign creator to cancel campaign
    function cancelCampaign(uint256 _campaignId) public {
        Campaign memory campaign = campaigns[_campaignId];

        require(
            campaign.creator != address(0),
            "Campaign with ID does not exist"
        );
        require(msg.sender == campaign.creator, "Only creator can cancel");
        require(block.timestamp < campaign.startAt, "Campaign already started");

        delete campaigns[_campaignId];

        emit FundraiserCampaignCanceled(campaign.name, msg.sender);
    }

    // Function that allows anybody to contribute ETH to campaigns
    function contributeToCampaign(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];

        require(
            campaign.creator != address(0),
            "Campaign with ID does not exist"
        );
        require(block.timestamp >= campaign.startAt, "Campaign did not start");
        require(block.timestamp <= campaign.endAt, "Campaign ended");

        campaign.contributed += msg.value;
        contributedAmount[_campaignId][msg.sender] += msg.value;

        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to contribute Ether");

        emit ContributedToCampaign(
            campaign.name,
            _campaignId,
            msg.sender,
            msg.value
        );
    }

    // Function that allows user to take back their contribution
    // to a certain campaign
    function retrieveFromCampaign(uint256 _campaignId, uint256 _ethAmount)
        public
    {
        Campaign storage campaign = campaigns[_campaignId];

        require(
            campaign.creator != address(0),
            "Campaign with ID does not exist"
        );
        require(block.timestamp >= campaign.startAt, "Campaign did not start");
        require(block.timestamp <= campaign.endAt, "Campaign ended");
        require(
            contributedAmount[_campaignId][msg.sender] >= _ethAmount,
            "Cannot retrieve more than you contributed"
        );

        campaign.contributed -= _ethAmount;
        contributedAmount[_campaignId][msg.sender] -= _ethAmount;

        (bool sent, ) = msg.sender.call{value: _ethAmount}("");
        require(sent, "Failed to retrieve Ether");

        emit RetrievedFromCampaign(
            campaign.name,
            _campaignId,
            msg.sender,
            _ethAmount
        );
    }

    // Function that allows campaign creator to claim funds
    function claimFromCampaign(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];

        require(
            campaign.creator != address(0),
            "Campaign with ID does not exist"
        );
        require(msg.sender == campaign.creator, "Only creator can claim");
        require(block.timestamp > campaign.endAt, "Campaign did not end");
        require(
            campaign.contributed >= campaign.goal,
            "Contribution is less than goal"
        );
        require(!campaign.claimed, "Already claimed");

        campaign.claimed = true;

        (bool sent, ) = msg.sender.call{value: campaign.contributed}("");
        require(sent, "Failed to claim Ether");

        emit ClaimedFromCampaign(campaign.name, _campaignId, msg.sender);
    }

    // Function that allows contributors to get refunded if campaign
    // is unsuccessful (meaning that fundraiser goal is not met)
    function refundFromCampaign(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];

        require(
            campaign.creator != address(0),
            "Campaign with ID does not exist"
        );
        require(block.timestamp > campaign.endAt, "Campaign did not end");
        require(
            campaign.contributed < campaign.goal,
            "Contribution is not less than goal"
        );
        require(
            contributedAmount[_campaignId][msg.sender] > 0,
            "Contribution is 0"
        );

        uint256 userContribution = contributedAmount[_campaignId][msg.sender];

        contributedAmount[_campaignId][msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: userContribution}("");
        require(sent, "Failed to refund Ether");

        emit RefundedFromCampaign(campaign.name, _campaignId, msg.sender);
    }
}
