// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor() ERC20("Name", "SYM") {
        this;
    }

    function mint(address to, uint256 amount) public virtual {
        _mint(to,amount);
    }

    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }
    
}