// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FairLottery {
    struct Prize {
        uint256 amount;  // 奖金数额
        string currency; // 奖金货币类型，目前支持 "ETH" 或 "USDT"
        uint count;      // 奖项的数量
    }

    Prize[] public prizes;
    uint public deadline;
    uint public userCount;
    uint public totalLocked;

    mapping(uint256 => bool) public selected; // 标记是否已被选中，减少 gas
    mapping(address => uint256) public balances; // 用户锁仓金额
    mapping(uint256 => address) public prizeWinners; // 获奖者地址


    // 构造函数，允许在部署时接收ETH
    constructor() payable {}
    fallback() external payable {}
    receive() external payable {}

    // KOL 锁仓函数
    function lockFunds() external payable {
        require(msg.value > 0, "Cannot lock 0 ETH");
        balances[msg.sender] += msg.value;
        totalLocked += msg.value;
        require(totalLocked >= calculateTotalPrizeAmount(), "Locked amount must be at least equal to total prize amount");
    }


    // 设置奖品和截止日期
    function setPrizes(Prize[] memory _prizes) public {
        require(_prizes.length > 0, "Invalid Params");
        for (uint i = 0; i < _prizes.length; i++) {
            prizes.push(_prizes[i]);
        }
    }

    // 更新用户数量
    function updateUserCount(uint _userCount) payable public {
        require(block.timestamp <= deadline - 3 minutes, "Deadline for updating has passed.");
        userCount = _userCount;
    }

    // 获取随机数
    function getRandom() public view returns (uint256 random) {
        for (uint i = 0; i < 8; i++) {
            bytes32 blockHash = blockhash(block.number - 1 - i);
            uint256 extracted = uint256(blockHash) & 0xffffffff;
            random ^= (extracted << (i * 32));
        }
    }

    // 抽取获奖者
    function drawWinners(uint[] memory prizesCounts) public returns (uint256[] memory winners) {
        require(block.timestamp >= deadline, "It is not yet time to draw winners.");
        require(userCount > 0, "Error user count.");

        uint256 totalPrizes = 0;
        for (uint i = 0; i < prizesCounts.length; i++) {
            totalPrizes += prizesCounts[i];
        }
        require(totalPrizes <= userCount, "Not enough users to fulfill all prizes.");

        winners = new uint256[](totalPrizes);
        uint256 count = 0;

        while (count < totalPrizes) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, getRandom(), count))) % userCount + 1;

            if (!selected[randomIndex]) {
                selected[randomIndex] = true;
                winners[count++] = randomIndex;
            }
        }

        return winners;
    }

    // 用户领奖
    function claimPrize(uint prizeIndex) public {
        require(prizeWinners[prizeIndex] == msg.sender, "You are not the winner");
        Prize memory prize = prizes[prizeIndex];
        require(totalLocked - prize.amount >= 0, "Not enough ETH in the contract");
        payable(msg.sender).transfer(prize.amount);
        totalLocked -= prize.amount;
    }

    // 计算所有奖项的总金额
    function calculateTotalPrizeAmount() public view returns (uint256 total) {
        for (uint i = 0; i < prizes.length; i++) {
            total += prizes[i].amount * prizes[i].count;
        }
        return total;
    }

    // getter 和 setter 函数
    function getDeadline() public view returns (uint) {
        return deadline;
    }

    function setDeadline(uint _newDeadline) public {
        require(_newDeadline > block.timestamp, "New deadline must be in the future.");
        deadline = _newDeadline;
    }

    function getUserCount() public view returns (uint) {
        return userCount;
    }

    function setUserCount(uint _newUserCount) public {
        userCount = _newUserCount;
    }

    function getPrize(uint index) public view returns (Prize memory) {
        return prizes[index];
    }

    function setPrize(uint index, uint256 amount, string memory currency, uint count) public {
        require(index < prizes.length, "Index out of bounds.");
        prizes[index] = Prize(amount, currency, count);
    }
}