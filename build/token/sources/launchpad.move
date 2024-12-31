#[allow(duplicate_alias)]
module token::launchpad {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use token::akr::AKR;
    use sui::balance::{Self, Balance};
    use sui::event;

    // Errors
    const ENotAuthorized: u64 = 0;
    const EInvalidAmount: u64 = 1;
    const EPoolNotActive: u64 = 2;
    const EInvalidBurnPercentage: u64 = 3;

    // Events
    public struct TokensPurchased has copy, drop {
        buyer: address,
        amount: u64,
        sui_amount: u64
    }

    public struct PoolCreated has copy, drop {
        owner: address,
        token_price: u64,
        min_purchase: u64,
        max_purchase: u64,
        burn_percentage: u64
    }

    public struct PoolEnded has copy, drop {
        owner: address,
        tokens_burned: u64
    }

    public struct LaunchPool has key {
        id: UID,
        owner: address,
        token_price: u64,
        min_purchase: u64,
        max_purchase: u64,
        burn_percentage: u64,
        active: bool,
        treasury_cap: TreasuryCap<AKR>,
        tokens: Balance<AKR>,
        sui_balance: Balance<SUI>
    }

    // View functions
    public fun get_pool_owner(pool: &LaunchPool): address {
        pool.owner
    }

    public fun get_token_price(pool: &LaunchPool): u64 {
        pool.token_price
    }

    public fun get_min_purchase(pool: &LaunchPool): u64 {
        pool.min_purchase
    }

    public fun get_max_purchase(pool: &LaunchPool): u64 {
        pool.max_purchase
    }

    public fun get_burn_percentage(pool: &LaunchPool): u64 {
        pool.burn_percentage
    }

    public fun get_pool_balance(pool: &LaunchPool): u64 {
        balance::value(&pool.tokens)
    }

    public fun get_sui_balance(pool: &LaunchPool): u64 {
        balance::value(&pool.sui_balance)
    }

    public fun is_pool_active(pool: &LaunchPool): bool {
        pool.active
    }

    public entry fun create_pool(
        treasury_cap: TreasuryCap<AKR>,
        tokens: Coin<AKR>,
        token_price: u64,
        min_purchase: u64,
        max_purchase: u64,
        burn_percentage: u64,
        ctx: &mut TxContext
    ) {
        assert!(burn_percentage <= 10000, EInvalidBurnPercentage);

        let pool = LaunchPool {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            token_price,
            min_purchase,
            max_purchase,
            burn_percentage,
            active: false,
            treasury_cap,
            tokens: coin::into_balance(tokens),
            sui_balance: balance::zero()
        };

        event::emit(PoolCreated {
            owner: tx_context::sender(ctx),
            token_price,
            min_purchase,
            max_purchase,
            burn_percentage
        });

        transfer::share_object(pool);
    }

    public entry fun set_pool_status(
        pool: &mut LaunchPool,
        active: bool,
        ctx: &mut TxContext
    ) {
        assert!(pool.owner == tx_context::sender(ctx), ENotAuthorized);
        pool.active = active;
    }

    public entry fun buy_tokens(
        pool: &mut LaunchPool,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(pool.active, EPoolNotActive);

        let payment_amount = coin::value(&payment);
        assert!(payment_amount >= pool.min_purchase, EInvalidAmount);
        assert!(payment_amount <= pool.max_purchase, EInvalidAmount);

        let token_amount = ((payment_amount as u128) * 1_000_000_000u128) / (pool.token_price as u128);
        let token_balance = balance::split(&mut pool.tokens, (token_amount as u64));

        balance::join(&mut pool.sui_balance, coin::into_balance(payment));

        event::emit(TokensPurchased {
            buyer: tx_context::sender(ctx),
            amount: (token_amount as u64),
            sui_amount: payment_amount
        });

        transfer::public_transfer(coin::from_balance(token_balance, ctx), tx_context::sender(ctx));
    }

    public entry fun end_pool(
        pool: &mut LaunchPool,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool.owner, ENotAuthorized);
        assert!(pool.active == true, EPoolNotActive);

        let remaining_tokens = balance::value(&pool.tokens);
        
        // Fix: Convert to u128 before multiplication to prevent overflow
        let burn_amount = ((remaining_tokens as u128) * (pool.burn_percentage as u128) / 10000u128) as u64;
        
        // Burn tokens using treasury cap
        if (burn_amount > 0) {
            let burn_coins = coin::from_balance(balance::split(&mut pool.tokens, burn_amount), ctx);
            coin::burn(&mut pool.treasury_cap, burn_coins);
        };

        // Transfer remaining tokens to owner
        let remaining = balance::value(&pool.tokens);
        if (remaining > 0) {
            let owner_coins = coin::from_balance(balance::withdraw_all(&mut pool.tokens), ctx);
            transfer::public_transfer(owner_coins, pool.owner);
        };

        // Transfer collected SUI to owner
        let sui_balance = balance::value(&pool.sui_balance);
        if (sui_balance > 0) {
            let owner_sui = coin::from_balance(balance::withdraw_all(&mut pool.sui_balance), ctx);
            transfer::public_transfer(owner_sui, pool.owner);
        };

        pool.active = false;

        event::emit(PoolEnded {
            owner: pool.owner,
            tokens_burned: burn_amount
        });
    }
}
