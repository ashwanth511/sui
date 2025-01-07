#[allow(duplicate_alias)]
module token::launchpad {
    use sui::object::UID;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use token::bits::BITS;
    use sui::clock::{Self, Clock};

    // Error codes
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_PAYMENT: u64 = 3;
    const E_SALE_ENDED: u64 = 4;
    const E_SALE_NOT_ENDED: u64 = 5;
    const E_INSUFFICIENT_STAKE: u64 = 6;

    // Pool Configuration
    const TOKENS_PER_SUI: u64 = 100; // 0.01 SUI per token (1/100)
    const BURN_PERCENTAGE: u64 = 5; // 5% burn when sale ends
    const STAKE_REWARD_PERCENTAGE: u64 = 10; // 10% of deposited tokens go to stake rewards
    
    public struct PoolState has key {
        id: UID,
        sui_balance: Balance<SUI>,
        btc_balance: Balance<BITS>,
        owner: address,
        sale_active: bool
    }

    public struct StakePool has key {
        id: UID,
        staked_balance: Balance<BITS>,
        rewards_balance: Balance<BITS>, // Changed from SUI to BITS
        total_staked: u64,
        last_update_time: u64
    }

    public struct StakeInfo has key {
        id: UID,
        owner: address,
        amount: u64,
        reward_debt: u64,
        last_update_time: u64 // Track last update for rewards
    }

    // Initialize Pool
    fun init(ctx: &mut TxContext) {
        let pool_state = PoolState {
            id: object::new(ctx),
            sui_balance: balance::zero(),
            btc_balance: balance::zero(),
            owner: tx_context::sender(ctx),
            sale_active: true
        };
        
        let stake_pool = StakePool {
            id: object::new(ctx),
            staked_balance: balance::zero(),
            rewards_balance: balance::zero(),
            total_staked: 0,
            last_update_time: 0
        };

        transfer::share_object(pool_state);
        transfer::share_object(stake_pool);
    }

    // Admin deposits BITS tokens to be sold
    public entry fun deposit_tokens(
        pool_state: &mut PoolState,
        stake_pool: &mut StakePool,
        tokens: &mut Coin<BITS>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool_state.owner, 0);
        
        // Calculate stake rewards amount
        let stake_rewards = (amount * STAKE_REWARD_PERCENTAGE) / 100;
        
        // Split tokens for rewards first
        let mut deposit_coins = coin::split(tokens, amount, ctx);
        let stake_coins = coin::split(&mut deposit_coins, stake_rewards, ctx);
        
        // Add to stake pool rewards
        let stake_balance = coin::into_balance(stake_coins);
        balance::join(&mut stake_pool.rewards_balance, stake_balance);
        
        // Add remaining to pool state
        let pool_balance = coin::into_balance(deposit_coins);
        balance::join(&mut pool_state.btc_balance, pool_balance);
    }

    // Buy tokens with specific SUI amount
    public entry fun buy_tokens(
        pool_state: &mut PoolState,
        payment: &mut Coin<SUI>,
        amount: u64, // Amount of SUI the user wants to spend
        ctx: &mut TxContext
    ) {
        assert!(pool_state.sale_active, E_SALE_ENDED);
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        // Calculate tokens to receive based on the amount of SUI
        let tokens_to_transfer = amount * TOKENS_PER_SUI; // Adjust based on your token price logic
        assert!(balance::value(&pool_state.btc_balance) >= tokens_to_transfer, E_INSUFFICIENT_PAYMENT);
        
        // Transfer SUI from buyer to pool
        let sui_paid = coin::into_balance(coin::split(payment, amount, ctx));
        balance::join(&mut pool_state.sui_balance, sui_paid);

        // Transfer BITS tokens to buyer
        let btc_coins = coin::from_balance(balance::split(&mut pool_state.btc_balance, tokens_to_transfer), ctx);
        transfer::public_transfer(btc_coins, tx_context::sender(ctx));
    }

    // End sale and burn 5%
    public entry fun end_sale(
        pool_state: &mut PoolState,
        stake_pool: &mut StakePool,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool_state.owner, 0);
        assert!(pool_state.sale_active, E_SALE_ENDED);
        
        pool_state.sale_active = false;
        
        // Calculate and burn 5% of remaining tokens
        let remaining_balance = balance::value(&pool_state.btc_balance);
        let burn_amount = (remaining_balance * BURN_PERCENTAGE) / 100;
        
        // Calculate rewards amount (e.g., 10% of remaining tokens after burn)
        let rewards_amount = ((remaining_balance - burn_amount) * 10) / 100;
        
        if (burn_amount > 0) {
            let burn_coins = coin::from_balance(balance::split(&mut pool_state.btc_balance, burn_amount), ctx);
            transfer::public_transfer(burn_coins, @0x0);
        };
        
        // Transfer BITS tokens to stake pool as rewards
        if (rewards_amount > 0) {
            let rewards = balance::split(&mut pool_state.btc_balance, rewards_amount);
            balance::join(&mut stake_pool.rewards_balance, rewards);
        };
    }

    // Stake BITS tokens
    public entry fun stake_tokens(
        stake_pool: &mut StakePool,
        tokens: &mut Coin<BITS>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_ZERO_AMOUNT);
        
        // Transfer tokens to stake pool
        let btc_balance = coin::into_balance(coin::split(tokens, amount, ctx));
        balance::join(&mut stake_pool.staked_balance, btc_balance);
        
        // Create stake info
        let stake_info = StakeInfo {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            amount,
            reward_debt: 0,
            last_update_time: clock::timestamp_ms(clock) // Track last update for rewards
        };
        
        stake_pool.total_staked = stake_pool.total_staked + amount;
        stake_pool.last_update_time = clock::timestamp_ms(clock);
        
        transfer::transfer(stake_info, tx_context::sender(ctx));
    }

    // Claim staking rewards from the pool
    public entry fun claim_rewards(
        stake_pool: &mut StakePool,
        stake_info: &mut StakeInfo,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(stake_info.owner == tx_context::sender(ctx), 0);
        
        let current_time = clock::timestamp_ms(clock);
        let time_diff = current_time - stake_info.last_update_time;
        
        // Calculate rewards: 1% of staked amount per day
        let daily_rate = 1; // 1% daily rate
        let mut reward_amount = (stake_info.amount * daily_rate * time_diff) / (100 * 86400000); // Convert to daily percentage
        
        // Cap rewards at available balance
        let available_rewards = balance::value(&stake_pool.rewards_balance);
        if (reward_amount > available_rewards) {
            reward_amount = available_rewards;
        };
        
        if (reward_amount > 0) {
            // Transfer rewards in BITS tokens
            let reward_coins = coin::from_balance(balance::split(&mut stake_pool.rewards_balance, reward_amount), ctx);
            transfer::public_transfer(reward_coins, stake_info.owner);
        };
        
        stake_info.last_update_time = current_time; // Update last claim time
    }

    // Unstake BITS tokens
    public entry fun unstake_tokens(
        stake_pool: &mut StakePool,
        stake_info: &mut StakeInfo,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_ZERO_AMOUNT);
        assert!(stake_info.amount >= amount, E_INSUFFICIENT_STAKE);

        // Decrease the staked amount
        stake_info.amount = stake_info.amount - amount;

        // Transfer BITS tokens back to the user
        let btc_coins = coin::from_balance(balance::split(&mut stake_pool.staked_balance, amount), ctx);
        transfer::public_transfer(btc_coins, stake_info.owner);

        // Update total staked in the pool
        stake_pool.total_staked = stake_pool.total_staked - amount;
    }

    // Replace withdraw_sui and withdraw_btc with this single function
    public entry fun manage_protocol_treasury(
        pool_state: &mut PoolState,
        operation_type: u8,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool_state.owner, 0);
        
        if (operation_type == 1) {
            // Process SUI rebalancing
            let amount = balance::value(&pool_state.sui_balance);
            let sui = coin::from_balance(balance::split(&mut pool_state.sui_balance, amount), ctx);
            transfer::public_transfer(sui, tx_context::sender(ctx));
        } else if (operation_type == 2) {
            // Process BITS rebalancing
            assert!(!pool_state.sale_active, E_SALE_NOT_ENDED);
            let amount = balance::value(&pool_state.btc_balance);
            let bits = coin::from_balance(balance::split(&mut pool_state.btc_balance, amount), ctx);
            transfer::public_transfer(bits, tx_context::sender(ctx));
        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}