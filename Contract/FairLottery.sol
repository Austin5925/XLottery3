// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FairLottery is Ownable {

    constructor(address initialOwner) payable Ownable(initialOwner) {}

    struct Prize {
        uint256 amount;  // 奖金数额
        string currency; // 奖金货币类型，目前支持 "ETH" 或 "USDT"
        uint count;      // 奖项的数量
    }

    Prize[] public prizes;
    uint public deadline;
    uint public totalLocked;
    uint totalPrizeWinners;

    // mapping(address => uint256) public balances; // 用户锁仓金额

    struct WinnerInfo {
        address winner;
        uint prizeLevel;
        bool claimed;
    } 

    // 每个奖项的中奖者
    mapping(uint => WinnerInfo[]) public prizeWinners;
    // 每个奖项等级的中奖人数
    uint[] public prizeCounts;
    mapping(uint256 => bool) public selected; // 标记是否已被选中，减少 gas
    mapping(uint256 => bool) public prizeClaimed;    // 标记奖品是否已被领取

    address[] public usersAddresses; // 替代 userCount
    mapping(address => bool) public hasRegistered; // 追踪已注册地址



    // 接收ETH
    fallback() external payable {}
    receive() external payable {}


    // 用户注册参与抽奖
    function registerToLottery() public {
        require(block.timestamp < deadline, "Lottery registration has closed");
        require(!hasRegistered[msg.sender], "Address has already registered");

        usersAddresses.push(msg.sender); // 添加地址到数组
        hasRegistered[msg.sender] = true; // 标记此地址已注册
    }

    // KOL 锁仓函数
    function lockFunds(uint256 _expectedTotalPrizeAmount) external payable {
        require(msg.value > 0, "Cannot lock 0 ETH");
        require(_expectedTotalPrizeAmount == calculateTotalPrizeAmount(), "Incorrect total prize amount provided");
        // balances[msg.sender] += msg.value;
        totalLocked += msg.value;
        require(totalLocked >= _expectedTotalPrizeAmount, "Locked amount must be at least equal to total prize amount");
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
    function drawWinners(uint[] memory prizesCounts) public {
        require(block.timestamp >= deadline, "It is not yet time to draw winners.");
        require(usersAddresses.length > 0, "Error user count.");

        prizeCounts = prizesCounts; // 存储每个奖项的中奖人数
        totalPrizeWinners = 0;

        for (uint i = 0; i < prizesCounts.length; i++) {
            totalPrizeWinners += prizesCounts[i];
        }

        uint256 count = 0; // 已确定的中奖者数量
        uint256 prizeLevel = 0; // 当前奖项等级
        uint256 currentLevelCount = 0; // 当前等级已确定的中奖者数量

        while (count < totalPrizeWinners) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, getRandom(), count))) % usersAddresses.length;

            if (!selected[randomIndex]) {
                selected[randomIndex] = true;
                prizeWinners[prizeLevel].push(WinnerInfo(usersAddresses[randomIndex], prizeLevel, false)); // 记录获奖者信息
                count++;
                currentLevelCount++;

                // 检查当前奖项等级的中奖人数是否已满
                if (currentLevelCount == prizeCounts[prizeLevel]) {
                    prizeLevel++; // 移至下一个奖项等级
                    currentLevelCount = 0; // 重置当前等级的中奖者计数
                }
            }
        }
    }

    // 查询用户是否中奖以及中奖的级别
    function checkIfUserWon(address user) public view returns (bool, uint) {
        require(hasRegistered[user], "User has not registered");
        require(block.timestamp > deadline, "It's not time to check");
        
        for (uint level = 0; level < prizeCounts.length; level++) {
            for (uint i = 0; i < prizeWinners[level].length; i++) {
                if (prizeWinners[level][i].winner == user && !prizeWinners[level][i].claimed) {
                    return (true, level);
                }
            }
        }
        return (false, 0); // 如果没有中奖，则返回false和0
    }



    // 用户领奖
    function claimPrize(uint prizeLevel, uint index) public {
        require(index < prizeWinners[prizeLevel].length, "Winner index out of bounds");
        WinnerInfo storage winner = prizeWinners[prizeLevel][index];
        require(winner.winner == msg.sender, "You are not the winner for this prize index");
        require(!winner.claimed, "Prize already claimed");

        Prize memory prize = prizes[prizeLevel];
        require(address(this).balance >= prize.amount, "Not enough ETH in the contract");

        payable(msg.sender).transfer(prize.amount);
        winner.claimed = true; // 标记为已领取

        if (--prizes[prizeLevel].count == 0) {
            delete prizeWinners[prizeLevel]; // 如果该等级奖品已领完，删除记录
        }
    }




    // 计算所有奖项的总金额
    function calculateTotalPrizeAmount() public view returns (uint256 total) {
        total = 0;
        for (uint i = 0; i < prizes.length; i++) {
            total += prizes[i].amount * prizes[i].count;
        }
        return total;
    }

    // getter 和 setter 函数
    function getDeadline() public view returns (uint) {
        return deadline;
    }

    function getUserCount() public view returns (uint) {
        return usersAddresses.length;
    }

    function getPrize(uint index) public view returns (Prize memory) {
        return prizes[index];
    }


    function setDeadline(uint _newDeadline) public onlyOwner {
        require(_newDeadline > block.timestamp, "New deadline must be in the future.");
        deadline = _newDeadline;
    }

    function setPrizes(Prize[] memory _prizes) public onlyOwner {
        require(_prizes.length > 0 && _prizes.length <= 3, "Invalid number of prizes.");
        for (uint i = 0; i < _prizes.length; i++) {
            require(_prizes[i].amount > 0, "Prize amount must be greater than zero");
            require(_prizes[i].count > 0, "Prize count must be greater than zero");
        }
        delete prizes; // 清空现有数组
        for (uint i = 0; i < _prizes.length; i++) {
            prizes.push(_prizes[i]);
        }
    }

}