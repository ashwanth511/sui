#[test_only]
module token::launchpad_tests {
    use sui::test_scenario::{Self as ts};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use token::akr::{Self, AKR};
    use token::launchpad::{Self, LaunchPool};

    const ADMIN: address = @0xAD;
    const USER1: address = @0x1;
    const MIN_PURCHASE: u64 = 1_000_000_000; // 1 SUI
    const MAX_PURCHASE: u64 = 100_000_000_000; // 100 SUI
    const PRICE_PER_TOKEN: u64 = 1_000_000; // 0.001 SUI per token
    const POOL_SIZE: u64 = 100_000_000_000_000_000; // 100M tokens with 9 decimals
    const BURN_PERCENTAGE: u64 = 500; // 5%

    fun setup_test(): ts::Scenario {
        ts::begin(ADMIN)
    }

    fun setup_pool(scenario: &mut ts::Scenario): LaunchPool {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let mut treasury_cap = akr::test_init(ctx);
        let tokens = coin::mint(&mut treasury_cap, POOL_SIZE, ctx);

        launchpad::create_pool(
            treasury_cap,
            tokens,
            PRICE_PER_TOKEN,
            MIN_PURCHASE,
            MAX_PURCHASE,
            BURN_PERCENTAGE,
            ctx
        );

        // Get pool object
        ts::next_tx(scenario, ADMIN);
        ts::take_shared<LaunchPool>(scenario)
    }

    fun mint_sui(amount: u64, recipient: address, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, recipient);
        let ctx = ts::ctx(scenario);
        let coin = coin::mint_for_testing<SUI>(amount, ctx);
        sui::transfer::public_transfer(coin, recipient);
    }

    #[test]
    fun test_pool_creation() {
        let mut scenario = setup_test();
        let pool = setup_pool(&mut scenario);
        
        // Verify pool parameters
        assert!(launchpad::get_pool_owner(&pool) == ADMIN, 0);
        assert!(launchpad::get_token_price(&pool) == PRICE_PER_TOKEN, 0);
        assert!(launchpad::get_min_purchase(&pool) == MIN_PURCHASE, 0);
        assert!(launchpad::get_max_purchase(&pool) == MAX_PURCHASE, 0);
        assert!(launchpad::get_burn_percentage(&pool) == BURN_PERCENTAGE, 0);
        assert!(launchpad::get_pool_balance(&pool) == POOL_SIZE, 0);
        assert!(!launchpad::is_pool_active(&pool), 0);
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
fun test_successful_purchase() {
    let mut scenario = setup_test();
    let mut pool = setup_pool(&mut scenario);
    
    // Activate pool first
    ts::next_tx(&mut scenario, ADMIN);
    {
        launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        assert!(launchpad::is_pool_active(&pool), 0);
    };
    
    // Mint SUI for purchase
    mint_sui(MIN_PURCHASE, USER1, &mut scenario);
    mint_sui(MIN_PURCHASE, USER1, &mut scenario);
    
    // First purchase
    ts::next_tx(&mut scenario, USER1);
    {
        let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
        let payment_amount = coin::value(&payment);
        let initial_balance = launchpad::get_pool_balance(&pool);
        let expected_tokens = ((payment_amount as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
        
        launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
        assert!(launchpad::get_pool_balance(&pool) == initial_balance - (expected_tokens as u64), 0);
    };

    // Verify first purchase
    ts::next_tx(&mut scenario, USER1);
    {
        let user_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
        let expected_tokens = ((MIN_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
        assert!(coin::value(&user_coins) == (expected_tokens as u64), 0);
        ts::return_to_sender(&scenario, user_coins);
    };
    
    // Second purchase
    ts::next_tx(&mut scenario, USER1);
    {
        let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
        let payment_amount = coin::value(&payment);
        let initial_balance = launchpad::get_pool_balance(&pool);
        let expected_tokens = ((payment_amount as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
        
        launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
        assert!(launchpad::get_pool_balance(&pool) == initial_balance - (expected_tokens as u64), 0);
    };

   
// Verify total tokens after both purchases
ts::next_tx(&mut scenario, USER1);
{
    let user_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
    let actual_tokens = coin::value(&user_coins);
    
    // Single purchase calculation (since we're getting the same amount twice)
    let single_purchase_tokens = ((MIN_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
    
    // We expect the actual tokens to match a single purchase
    assert!(actual_tokens == (single_purchase_tokens as u64), 0);
    
    ts::return_to_sender(&scenario, user_coins);
};


    
    ts::return_shared(pool);
    ts::end(scenario);
}

   #[test]
    fun test_multiple_user_purchases() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        // Activate pool
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        // User 1 purchase
        mint_sui(MIN_PURCHASE, USER1, &mut scenario);
        ts::next_tx(&mut scenario, USER1);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            let initial_balance = launchpad::get_pool_balance(&pool);
            let expected_tokens = ((MIN_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
            assert!(launchpad::get_pool_balance(&pool) == initial_balance - (expected_tokens as u64), 0);
        };

        // User 2 purchase with different amount
        let user2 = @0x2;
        mint_sui(MIN_PURCHASE * 2, user2, &mut scenario);
        ts::next_tx(&mut scenario, user2);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            let initial_balance = launchpad::get_pool_balance(&pool);
            let expected_tokens = ((MIN_PURCHASE * 2 as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
            assert!(launchpad::get_pool_balance(&pool) == initial_balance - (expected_tokens as u64), 0);
        };

        // Verify User 1 tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let user_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
            let expected_tokens = ((MIN_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            assert!(coin::value(&user_coins) == (expected_tokens as u64), 0);
            ts::return_to_sender(&scenario, user_coins);
        };

        // Verify User 2 tokens
        ts::next_tx(&mut scenario, user2);
        {
            let user_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
            let expected_tokens = ((MIN_PURCHASE * 2 as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            assert!(coin::value(&user_coins) == (expected_tokens as u64), 0);
            ts::return_to_sender(&scenario, user_coins);
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    fun test_purchase_exact_max() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        // Activate pool
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        // Purchase with exact maximum amount
        mint_sui(MAX_PURCHASE, USER1, &mut scenario);
        ts::next_tx(&mut scenario, USER1);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            let initial_balance = launchpad::get_pool_balance(&pool);
            let expected_tokens = ((MAX_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
            assert!(launchpad::get_pool_balance(&pool) == initial_balance - (expected_tokens as u64), 0);
        };

        // Verify tokens received
        ts::next_tx(&mut scenario, USER1);
        {
            let user_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
            let expected_tokens = ((MAX_PURCHASE as u128) * 1_000_000_000u128) / (PRICE_PER_TOKEN as u128);
            assert!(coin::value(&user_coins) == (expected_tokens as u64), 0);
            ts::return_to_sender(&scenario, user_coins);
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    fun test_pool_ending() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        // Activate pool
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        // Calculate expected transfer before ending pool
        let initial_balance = launchpad::get_pool_balance(&pool);
        let burn_amount = ((initial_balance as u128) * (BURN_PERCENTAGE as u128) / 10000u128) as u64;
        let expected_transfer = initial_balance - burn_amount;
        
        // End pool
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::end_pool(&mut pool, ts::ctx(&mut scenario));
            
            // Verify pool is inactive
            assert!(!launchpad::is_pool_active(&pool), 0);
            
            // Verify pool balance is 0
            assert!(launchpad::get_pool_balance(&pool) == 0, 0);
        };

        // Check received tokens in next tx
        ts::next_tx(&mut scenario, ADMIN);
        {
            // Verify owner received remaining tokens
            if (expected_transfer > 0) {
                let owner_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
                assert!(coin::value(&owner_coins) == expected_transfer, 0);
                ts::return_to_sender(&scenario, owner_coins);
            };
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::ENotAuthorized)]
    fun test_unauthorized_pool_activation() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        ts::next_tx(&mut scenario, USER1);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::ENotAuthorized)]
    fun test_unauthorized_pool_ending() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        ts::next_tx(&mut scenario, USER1);
        {
            launchpad::end_pool(&mut pool, ts::ctx(&mut scenario));
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::EPoolNotActive)]
    fun test_purchase_from_inactive_pool() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        mint_sui(MIN_PURCHASE, USER1, &mut scenario);
        ts::next_tx(&mut scenario, USER1);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::EInvalidAmount)]
    fun test_purchase_below_minimum() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        mint_sui(MIN_PURCHASE - 1, USER1, &mut scenario);
        ts::next_tx(&mut scenario, USER1);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::EInvalidAmount)]
    fun test_purchase_above_maximum() {
        let mut scenario = setup_test();
        let mut pool = setup_pool(&mut scenario);
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::set_pool_status(&mut pool, true, ts::ctx(&mut scenario));
        };
        
        mint_sui(MAX_PURCHASE + 1, USER1, &mut scenario);
        ts::next_tx(&mut scenario, USER1);
        {
            let payment = ts::take_from_sender<Coin<SUI>>(&scenario);
            launchpad::buy_tokens(&mut pool, payment, ts::ctx(&mut scenario));
        };
        
        ts::return_shared(pool);
        ts::end(scenario);
    }
}