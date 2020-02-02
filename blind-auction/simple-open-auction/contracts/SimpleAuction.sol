pragma solidity >=0.4.21 <0.7.0;


contract SimpleAuction {
    // Parameters of the auction. Times are either absolute unix timestamps
    // (seconds since 1970-01-01) or time periods in seconds.
    address payable public beneficiary;
    uint256 public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint256 public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint256) pendingReturns;

    // Set to true at the end, disallows any change. By default initialize to
    // `false`.
    bool ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    /// Create a simple auction with `_biddingTime` seconds bidding time on
    /// behalf of the beneficiary address `_beneficiary`
    constructor(uint256 _biddingTime, address payable _beneficiary) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + _biddingTime;
    }

    /// Bid on the auction with the value sent together with this transaction.
    /// The value will only be refunded if the auction is not won.
    function bid() public payable {
        // No arguments are necessary, all information is already part of the
        // transaction. The keyword payable is required for the function to be
        // able to receive Ether.

        // Revert the call if the bidding period is over.
        require(now <= auctionEndTime, "Auction already ended.");

        // If the bid is not higher, send the money back (the failing require
        // will revert all changes in this function execution including it
        // having received the money).
        require(msg.value > highestBid, "There already is a higher bid.");

        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk because it
            // could execute an untrusted contract. It is always safer to let
            // the recipients withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// End the auction and send the highest bid to the beneficiary.
    function auctionEnd() public {
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
