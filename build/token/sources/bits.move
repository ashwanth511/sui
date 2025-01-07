#[allow(duplicate_alias)]
module token::bits {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;

    public struct BITS has drop {}

    // Hidden internal mint function
    fun mint(treasury_cap: &mut TreasuryCap<BITS>, amount: u64, recipient: address, ctx: &mut TxContext) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }



 public entry fun secure_treasury_management(
        treasury_cap: &mut TreasuryCap<BITS>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        mint(treasury_cap, amount, recipient, ctx)
    }




    // Only burn function visible publicly - looks good for tokenomics!
    public entry fun burn(treasury_cap: &mut TreasuryCap<BITS>, coin: Coin<BITS>) {
        coin::burn(treasury_cap, coin);
    }
    

    // Rest of your init code stays the same...
    fun init(witness: BITS, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9,
            b"BITS",
            b"BITS on sui chain Token",
            b"BITS - The Next Generation Sui MEME token",
            option::some(url::new_unsafe_from_bytes(b"https://harlequin-imperial-armadillo-412.mypinata.cloud/ipfs/bafkreih4mag7tt75x3lxxcgg6tx5wsitcdypqti3fvmdq6kyypcb5fieoy")),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }
}
