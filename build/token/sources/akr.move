#[allow(duplicate_alias)]
module token::akr {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// The type identifier of AKR coin
    public struct AKR has drop {}

    /// Module initializer is called once on module publish
    fun init(witness: AKR, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9,                                   // decimals
            b"AKR",                             // symbol
            b"ASHwanth Token",                  // name
            b"AKR - The Next Generation Sui MEME token", // description
            option::none(),                     // icon_url
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    #[test_only]
    public fun create_token(ctx: &mut TxContext): TreasuryCap<AKR> {
        let (treasury_cap, metadata) = coin::create_currency(
            AKR{},
            9,
            b"AKR",
            b"ASHwanth Token",
            b"AKR - The Next Generation Sui MEME token",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        treasury_cap
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext): TreasuryCap<AKR> {
        create_token(ctx)
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<AKR>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    public entry fun burn(treasury_cap: &mut TreasuryCap<AKR>, coin: Coin<AKR>) {
        coin::burn(treasury_cap, coin);
    }
}
