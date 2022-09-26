/// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract PromoStake {
    uint256 private _stakeStart = 1664370000;
    uint256 private _stakeEnd = 1664974800;
    uint256 private _stakeMultiplier = 2480150000000;
    uint256 private _minStake = 1000 ether;
    address private _owner;

    struct Stake {
        uint256 timestamp;
        uint256 amount;
    }

    mapping(address => Stake) private _stakes;
    mapping(address => Stake) private _withdrawals;

    modifier onlyDuringStaking() {
        require(
            block.timestamp >= _stakeStart && block.timestamp <= _stakeEnd,
            "Not stake duration"
        );
        _;
    }

    modifier onlyAfterStakeEnds() {
        require(block.timestamp > _stakeEnd, "Stake still continues");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function getStake(address user) public view returns (Stake memory) {
        return _stakes[user];
    }

    function getWithdrawal(address user) public view returns (Stake memory) {
        return _withdrawals[user];
    }

    function calculateReward(uint256 stakeStart, uint256 amount)
        public
        view
        returns (uint256)
    {
        return ((_stakeEnd - stakeStart) * _stakeMultiplier * amount) / 10**18;
    }

    function deposit() public payable {}

    function claimRemaining() public onlyOwner onlyAfterStakeEnds {
        payable(msg.sender).transfer(address(this).balance);
    }

    function stake() public payable onlyDuringStaking {
        require(
            getStake(msg.sender).timestamp == 0,
            "You already have a stake"
        );
        require(msg.value >= _minStake, "Your stake amount is too low");
        _insertStake(msg.sender, msg.value);
    }

    function unstake() public onlyAfterStakeEnds {
        Stake memory userStake = getStake(msg.sender);
        require(userStake.timestamp != 0, "You dont have stake");
        uint256 rewardAmount = calculateReward(
            userStake.timestamp,
            userStake.amount
        );
        _insertWithdrawal(msg.sender, userStake.amount + rewardAmount);
        _deleteStake(msg.sender);
    }

    function withdraw() public onlyAfterStakeEnds {
        Stake memory userWithdrawal = getWithdrawal(msg.sender);
        require(
            userWithdrawal.timestamp + 86400 < block.timestamp,
            "You can withdraw in 24 hours"
        );
        payable(msg.sender).transfer(userWithdrawal.amount);
        _deleteWithdrawal(msg.sender);
    }

    function _insertStake(address user, uint256 amount) private {
        _stakes[user].timestamp = block.timestamp;
        _stakes[user].amount = amount;
    }

    function _deleteStake(address user) private {
        delete _stakes[user];
    }

    function _insertWithdrawal(address user, uint256 amount) private {
        _withdrawals[user].timestamp = block.timestamp;
        _withdrawals[user].amount = amount;
    }

    function _deleteWithdrawal(address user) private {
        delete _withdrawals[user];
    }
}
