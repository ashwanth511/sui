#[test_only]
module token::token_tests {
    use sui::test_scenario::{Self as ts};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::test_utils::assert_eq;
    use token::akr::{Self, AKR};

    const ADMIN: address = @0xAD;
    const USER1: address = @0x1;
    const TOKEN_AMOUNT: u64 = 100_000_000_000_000_000; // 100M tokens with 9 decimals

    fun setup_test(): ts::Scenario {
        ts::begin(ADMIN)
    }

    fun mint_test_tokens(scenario: &mut ts::Scenario): (TreasuryCap<AKR>, Coin<AKR>) {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let mut treasury_cap = akr::test_init(ctx);
        let tokens = coin::mint(&mut treasury_cap, TOKEN_AMOUNT, ctx);
        (treasury_cap, tokens)
    }

    #[test]
    fun test_token_initialization() {
        let mut scenario = setup_test();
        
        // Test token initialization
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut treasury_cap = akr::test_init(ts::ctx(&mut scenario));
            let total_supply = coin::mint(&mut treasury_cap, 0, ts::ctx(&mut scenario));
            assert_eq(coin::value(&total_supply), 0);
            coin::burn(&mut treasury_cap, total_supply);
            transfer::public_transfer(treasury_cap, ADMIN);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_token_minting() {
        let mut scenario = setup_test();
        let (treasury_cap, coins) = mint_test_tokens(&mut scenario);
        
        // Verify initial supply
        assert_eq(coin::value(&coins), TOKEN_AMOUNT);
        
        // Clean up
        transfer::public_transfer(treasury_cap, ADMIN);
        transfer::public_transfer(coins, ADMIN);
        
        ts::end(scenario);
    }

    #[test]
    fun test_token_burning() {
        let mut scenario = setup_test();
        let (mut treasury_cap, mut coins) = mint_test_tokens(&mut scenario);
        
        // Burn half of the tokens
        ts::next_tx(&mut scenario, ADMIN);
        {
            let burn_amount = TOKEN_AMOUNT / 2;
            let coins_to_burn = coin::split(&mut coins, burn_amount, ts::ctx(&mut scenario));
            coin::burn(&mut treasury_cap, coins_to_burn);
            
            // Verify remaining supply
            assert_eq(coin::value(&coins), TOKEN_AMOUNT - burn_amount);
        };
        
        // Clean up
        transfer::public_transfer(treasury_cap, ADMIN);
        transfer::public_transfer(coins, ADMIN);
        
        ts::end(scenario);
    }

    #[test]
    fun test_token_transfer() {
        let mut scenario = setup_test();
        let (treasury_cap, mut coins) = mint_test_tokens(&mut scenario);
        
        // Transfer tokens to USER1
        ts::next_tx(&mut scenario, ADMIN);
        {
            let transfer_amount = TOKEN_AMOUNT / 2;
            let coins_to_transfer = coin::split(&mut coins, transfer_amount, ts::ctx(&mut scenario));
            transfer::public_transfer(coins_to_transfer, USER1);
            
            // Verify balances
            assert_eq(coin::value(&coins), TOKEN_AMOUNT - transfer_amount);
        };
        
        // Verify USER1 received tokens
        ts::next_tx(&mut scenario, USER1);
        {
            let received_coins = ts::take_from_sender<Coin<AKR>>(&scenario);
            assert_eq(coin::value(&received_coins), TOKEN_AMOUNT / 2);
            ts::return_to_sender(&scenario, received_coins);
        };
        
        // Clean up
        transfer::public_transfer(treasury_cap, ADMIN);
        transfer::public_transfer(coins, ADMIN);
        
        ts::end(scenario);
    }

    #[test]
    fun test_token_merge() {
        let mut scenario = setup_test();
        let (treasury_cap, mut coins) = mint_test_tokens(&mut scenario);
        
        // Split and merge tokens
        ts::next_tx(&mut scenario, ADMIN);
        {
            let split_amount = TOKEN_AMOUNT / 2;
            let coins_split = coin::split(&mut coins, split_amount, ts::ctx(&mut scenario));
            assert_eq(coin::value(&coins), TOKEN_AMOUNT - split_amount);
            assert_eq(coin::value(&coins_split), split_amount);
            
            // Merge back
            coin::join(&mut coins, coins_split);
            assert_eq(coin::value(&coins), TOKEN_AMOUNT);
        };
        
        // Clean up
        transfer::public_transfer(treasury_cap, ADMIN);
        transfer::public_transfer(coins, ADMIN);
        
        ts::end(scenario);
    }
}