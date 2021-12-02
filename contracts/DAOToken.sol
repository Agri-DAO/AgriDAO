//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import openzeppelin ERC20, Ownable etc...
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 *  IMPORT USER AGREEMENT HERE
 */

contract DAOToken is ERC20, Ownable {
    constructor(uint256 initSupply, address initOwner) public ERC20("tDAO", "TestDAO") {
        _mint(initOwner, initSupply);
    }

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    } 
}
