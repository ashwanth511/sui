#[test_only]
module token::launchpad_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use token::bits::{Self, BITS};
    use token::launchpad::{Self, PoolState, StakePool, StakeInfo};
    use sui::test_utils::assert_eq;

    const ADMIN: address = @0xAD;
    const USER1: address = @0x1;
    const USER2: address = @0x2;

    // Test initialization
    #[test]
    fun test_init() {
        let scenario = ts::begin(ADMIN);
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };

        // Verify pool state
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool_state = ts::take_shared<PoolState>(&scenario);
            assert!(launchpad::is_active(&pool_state), 0);
            ts::return_shared(pool_state);

            let stake_pool = ts::take_shared<StakePool>(&scenario);
            assert!(launchpad::get_total_staked(&stake_pool) == 0, 0);
            ts::return_shared(stake_pool);
        };
        ts::end(scenario);
    }

    // Test token deposit and buying
    #[test]
    fun test_deposit_and_buy() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };

        // Admin deposits tokens
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool_state = ts::take_shared<PoolState>(&scenario);
            let mark_coins = coin::mint_for_testing<BITS>(1000000, ts::ctx(&mut scenario));
            launchpad::deposit_tokens(&mut pool_state, &mut mark_coins, 1000000, ts::ctx(&mut scenario));
            coin::destroy_for_testing(mark_coins);
            ts::return_shared(pool_state);
        };

        // User1 buys tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let pool_state = ts::take_shared<PoolState>(&scenario);
            let sui_coins = coin::mint_for_testing<SUI>(10, ts::ctx(&mut scenario));
            launchpad::buy_tokens(&mut pool_state, &mut sui_coins, 10, ts::ctx(&mut scenario));
            coin::destroy_for_testing(sui_coins);
            ts::return_shared(pool_state);
        };

        ts::end(scenario);
    }

    // Test staking
    #[test]
    fun test_staking() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
            clock::create_for_testing(ts::ctx(&mut scenario));
        };

        // User stakes tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let stake_pool = ts::take_shared<StakePool>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            let mark_coins = coin::mint_for_testing<BITS>(1000, ts::ctx(&mut scenario));
            
            launchpad::stake_tokens(&mut stake_pool, &mut mark_coins, 1000, &clock, ts::ctx(&mut scenario));
            
            coin::destroy_for_testing(mark_coins);
            ts::return_shared(stake_pool);
            ts::return_shared(clock);
        };

        // Advance time and claim rewards
        ts::next_tx(&mut scenario, USER1);
        {
            let stake_pool = ts::take_shared<StakePool>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            let stake_info = ts::take_from_sender<StakeInfo>(&scenario);
            
            clock::increment_for_testing(&mut clock, 24 * 60 * 60 * 1000); // 1 day
            launchpad::claim_rewards(&mut stake_pool, &mut stake_info, &clock, ts::ctx(&mut scenario));
            
            ts::return_to_sender(&scenario, stake_info);
            ts::return_shared(stake_pool);
            ts::return_shared(clock);
        };

        ts::end(scenario);
    }

    // Test sale end and burn
    #[test]
    fun test_end_sale_and_burn() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };

        // Admin deposits tokens
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool_state = ts::take_shared<PoolState>(&scenario);
            let mark_coins = coin::mint_for_testing<BITS>(1000000, ts::ctx(&mut scenario));
            launchpad::deposit_tokens(&mut pool_state, &mut mark_coins, 1000000, ts::ctx(&mut scenario));
            coin::destroy_for_testing(mark_coins);
            ts::return_shared(pool_state);
        };

        // End sale
        ts::next_tx(&mut scenario, ADMIN);
        {
            let pool_state = ts::take_shared<PoolState>(&scenario);
            launchpad::end_sale(&mut pool_state, ts::ctx(&mut scenario));
            assert!(!launchpad::is_active(&pool_state), 0);
            ts::return_shared(pool_state);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_launchpad_initialization() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize launchpad
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };
        
        // Verify ICO state
        ts::next_tx(&mut scenario, ADMIN);
        {
            let ico_state = ts::take_shared<ICOState>(&scenario);
            assert!(ts::has_most_recent_shared<ICOState>(), 0);
            ts::return_shared(ico_state);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_token_purchase() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize launchpad and token
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };
        
        let treasury_cap = bits::test_init(ts::ctx(&mut scenario));
        
        // User buys tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let ico_state = ts::take_shared<ICOState>(&scenario);
            let payment = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario)); // 1 SUI
            
            launchpad::buy_tokens(
                &mut ico_state,
                &mut treasury_cap,
                &mut payment,
                ts::ctx(&mut scenario)
            );
            
            // Verify token receipt
            let received_tokens = ts::take_from_sender<Coin<BITS>>(&scenario);
            assert_eq(coin::value(&received_tokens), 100_000_000_000); // 100 BITS
            
            ts::return_to_sender(&scenario, received_tokens);
            ts::return_shared(ico_state);
            transfer::public_transfer(payment, USER1);
        };
        
        transfer::public_transfer(treasury_cap, ADMIN);
        ts::end(scenario);
    }

    #[test]
    fun test_sui_withdrawal() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize launchpad and token
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };
        
        let treasury_cap = bits::test_init(ts::ctx(&mut scenario));
        
        // User buys tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let ico_state = ts::take_shared<ICOState>(&scenario);
            let payment = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario)); // 1 SUI
            
            launchpad::buy_tokens(
                &mut ico_state,
                &mut treasury_cap,
                &mut payment,
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(ico_state);
            transfer::public_transfer(payment, USER1);
        };
        
        // Admin withdraws SUI
        ts::next_tx(&mut scenario, ADMIN);
        {
            let ico_state = ts::take_shared<ICOState>(&scenario);
            launchpad::withdraw_sui(&mut ico_state, ts::ctx(&mut scenario));
            
            // Verify admin received SUI
            let received_sui = ts::take_from_sender<Coin<SUI>>(&scenario);
            assert_eq(coin::value(&received_sui), 1_000_000_000);
            
            ts::return_to_sender(&scenario, received_sui);
            ts::return_shared(ico_state);
        };
        
        transfer::public_transfer(treasury_cap, ADMIN);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_zero_amount_purchase() {
        let scenario = ts::begin(ADMIN);
        
        // Initialize launchpad and token
        ts::next_tx(&mut scenario, ADMIN);
        {
            launchpad::init_for_testing(ts::ctx(&mut scenario));
        };
        
        let treasury_cap = bits::test_init(ts::ctx(&mut scenario));
        
        // Try to buy with zero SUI
        ts::next_tx(&mut scenario, USER1);
        {
            let ico_state = ts::take_shared<ICOState>(&scenario);
            let payment = coin::mint_for_testing<SUI>(0, ts::ctx(&mut scenario));
            
            launchpad::buy_tokens(
                &mut ico_state,
                &mut treasury_cap,
                &mut payment,
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(ico_state);
            transfer::public_transfer(payment, USER1);
        };
        
        transfer::public_transfer(treasury_cap, ADMIN);
        ts::end(scenario);
    }
}