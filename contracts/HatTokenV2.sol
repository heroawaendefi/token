// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HatTokenV2 is
    Context,
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable,
    Ownable
{
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 _liquidityFee;
    address _liquidityKeeper;

    mapping(address => bool) _blockSenders;
    mapping(address => bool) _blockReceivers;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _liquidityFee = 50;
        _liquidityKeeper = owner();

        _mint(owner(), 10**9 * 10**18);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Hero Awaken Token: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Hero Awaken Token: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        require(!_blockSenders[from], "Hero Awaken Token: the sender has been blocked");
        require(!_blockReceivers[to], "Hero Awaken Token: the receiver has been blocked");

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    function liquidityFee() external view returns (uint256) {
        return _liquidityFee;
    }

    function liquidityKeeper() external view returns (address) {
        return _liquidityKeeper;
    }

    function blocked(address user) external view returns (bool, bool) {
        return (_blockSenders[user], _blockReceivers[user]);
    }

    function blockUser(address user, bool can_send, bool can_receive) public onlyOwner {
        _blockSenders[user] = can_send;
        _blockReceivers[user] = can_receive;
    }

    function setLiquidityFee(uint256 fee) public onlyOwner {
        require(
            fee >= 0 && fee <= 1000,
            "Hero Awaken Token: liquidity fee must between 0 and 1000"
        );

        _liquidityFee = fee;
    }

    function setLiquidityKeeper(address keeper) public onlyOwner {
        _liquidityKeeper = keeper;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 fee = amount.mul(_liquidityFee).div(1000);
        amount -= fee;

        super._transfer(from, to, amount);
        super._transfer(from, _liquidityKeeper, fee);
    }
}
