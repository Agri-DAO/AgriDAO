pragma solidity ^0.8.4;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Intermediate contract for obtaining index prices, can be used in future to get custom
//prices


//Can use a price converter function to derive different price denominations - eg use eth/usd and aud/usd to get eth/aud
contract OraclePrice {
    mapping(string => address) public priceOracles;
    AggregatorV3Interface internal priceFeed;

    constructor () {
        priceOracles["USDC/ETH"] = 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf;
        priceOracles["DAI/USD"] = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
        priceFeed = AggregatorV3Interface(priceOracles["USDC/ETH"]);
        

    }

    function addOracle(string memory pair, address a) public {
      priceOracles[pair] = a;
    }

    function setOracle(string memory pair) public {
      priceFeed = AggregatorV3Interface(priceOracles[pair]);
    }


    function getPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }



}
