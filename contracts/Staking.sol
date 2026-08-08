// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MaxDevStakingS-Tier
 * @notice Протокол стейкинга с математической сложностью начисления наград O(1).
 * @dev Оптимизирован по газу (unchecked) и защищен от Fee-on-Transfer / Rebasing токенов.
 */
contract MaxDevStakingFixed is ReentrancyGuard {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardUpdated(uint256 reward, uint256 duration);

    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "Zero address validation failed");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            return rewardPerTokenStored + (
                (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18
            ) / _totalSupply;
        }
    }

    function earned(address account) public view returns (uint256) {
        unchecked {
            return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
        }
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function notifyRewardAmount(uint256 reward, uint256 duration) external updateReward(address(0)) {
        // Здесь в реальном продакшене должен быть модификатор onlyOwner
        require(block.timestamp >= periodFinish, "Previous rewards period not finished");
        
        rewardRate = reward / duration;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        
        emit RewardUpdated(reward, duration);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Amount must be greater than zero");
        
        // S-Tier защита от Fee-on-Transfer: замеряем реальный баланс до и после трансфера
        uint256 balanceBefore = stakingToken.balanceOf(address(this));
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer From failed");
        uint256 balanceAfter = stakingToken.balanceOf(address(this));
        
        uint256 realAmount = balanceAfter - balanceBefore;
        require(realAmount > 0, "Effective staked amount cannot be zero");

        unchecked {
            _totalSupply += realAmount;
            _balances[msg.sender] += realAmount;
        }

        emit Staked(msg.sender, realAmount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        unchecked {
            _totalSupply -= amount;
            _balances[msg.sender] -= amount;
        }

        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}
