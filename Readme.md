Build the updated contract:
Code
CopyInsert
sui move build --skip-fetch-latest-git-deps
Publish the updated contract:
Code
CopyInsert
sui client publish --gas-budget 100000000 --skip-fetch-latest-git-deps

upgrdae cap:  0x87a0a9f34b038c9084ffecfbcf1d32a3036b1ef4cbbfb5ba376f61bd60766c64   
meatadat:   0x5db6252eeffd3098d949292780e842122b8adbd86c1510d1f74cf604b4b06ce6 
treasui :  0x2cdd7d1293ddaf01b3310e087438507753c31d4df431d763cb1a7b03403309ea   
package id: 0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a 
stake pool : 0xfa1af904bdaa1cccd91c27c2614dce6981c3b2220912e06de84e40c92aab346b   
pool state :0xa150222cfd213773d39608e9b4e20f769ef68fa4faac4cd9d740043cfa734853 


address: 0xa31d3e6316e73b92de452500537f69beec94db8dd12b9eb64fa12cfbb0920198
Mint TONY tokens (as admin):

sui client call \
    --package <PACKAGE_ID> \
    --module bits \
    --function secure_treasury_management \
    --args <TREASURY_CAP_ID> "1000000000000000000" <YOUR_ADDRESS> \
    --gas-budget 10000000

sui client call 
    --package 0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a 
    --module bits 
    --function secure_treasury_management 
    --args 0x2cdd7d1293ddaf01b3310e087438507753c31d4df431d763cb1a7b03403309ea  "1000000000000000000" 0xa31d3e6316e73b92de452500537f69beec94db8dd12b9eb64fa12cfbb0920198
    --gas-budget 10000000


coin did:0x0839a7e45bd8da5a0edfb0f11debc2d7962c6c850b1175e7b532f70d68ba95cc 

Admin deposits BITS tokens to the pool:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function deposit_tokens \
    --args <POOL_STATE_ID> <STAKE_POOL_ID> <MARK_COIN_ID> <AMOUNT> \
    --gas-budget 10000000

sui client call 
    --package 0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a 
    --module launchpad 
    --function deposit_tokens 
    --args 0xa150222cfd213773d39608e9b4e20f769ef68fa4faac4cd9d740043cfa734853   0xfa1af904bdaa1cccd91c27c2614dce6981c3b2220912e06de84e40c92aab346b 0x0839a7e45bd8da5a0edfb0f11debc2d7962c6c850b1175e7b532f70d68ba95cc  200000000000000000
    --gas-budget 10000000


User buys tokens:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function buy_tokens \
    --args <POOL_STATE_ID> <USER_SUI_COIN_ID>  <aMOUNT>
    --gas-budget 10000000


sui client call 
     --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50 
    --module launchpad 
    --function buy_tokens 
     --args 0x3cca1bac7ff6815ab722a0860ec9b2cee913545f957f44d42c683a9bcbc4722e
    0xc33002296a320bdb2418ebb5dcc873ca5d63f4c519df5dd3d28877f9d3f5d19f  10000000000
    --gas-budget 10000000




User stakes BITS tokens:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function stake_tokens \
    --args <STAKE_POOL_ID> <MARK_COIN_ID> <AMOUNT_TO_STAKE>  <clockid>\
    --gas-budget 10000000

    remeber teh clockid is set to 0x6 by deagult bro 

sui client call 
    --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50  
    --module launchpad 
    --function stake_tokens 
    --args 0xf4f6a91fccc054804f93793f51866a5449a5ff982d7df51024f57928067b526b 0xb7d7593a510084cb37a7950cac3447b97b87e3b688f9ebec2ef87a7e22c08b1d  500000000000  0x6
    --gas-budget 10000000

User claims rewards:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function claim_rewards \
    --args <STAKE_POOL_ID> <STAKE_INFO_ID> <clock
    -id>\
    --gas-budget 10000000



sui client call 
   --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50  
    --module launchpad 
    --function claim_rewards 
    --args 0xf4f6a91fccc054804f93793f51866a5449a5ff982d7df51024f57928067b526b   0x52da3dab03d6fb4c9a573d6bfb9aa0984786f202b898e9f22cae3cfe95a21366  0x6
    --gas-budget 10000000










//unstake tokens

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function unstake_tokens \
    --args <STAKE_POOL_ID> <STAKE_INFO_ID> <amount>\
    --gas-budget 10000000


sui client call 
    --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50 
    --module launchpad 
    --function unstake_tokens 
    --args 0xf4f6a91fccc054804f93793f51866a5449a5ff982d7df51024f57928067b526b 0x52da3dab03d6fb4c9a573d6bfb9aa0984786f202b898e9f22cae3cfe95a21366 400000000000 
    --gas-budget 10000000


Admin withdraws collected SUI:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function manage_protocol_treasury \
    --args <POOL_STATE_ID> <operation_type> \
    --gas-budget 10000000


sui client call 
    --package 0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a
    --module launchpad 
    --function manage_protocol_treasury 
    --args 0xa150222cfd213773d39608e9b4e20f769ef68fa4faac4cd9d740043cfa734853 1
    --gas-budget 10000000









1: for the wthsraw sui 
2 for withdraw bits

sui client call 
    --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50 
    --module launchpad 
    --function manage_protocol_treasury 
    --args 0x3cca1bac7ff6815ab722a0860ec9b2cee913545f957f44d42c683a9bcbc4722e  1 
    --gas-budget 10000000

Admin ends the sale and burns 5% of remaining tokens:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function end_sale \
    --args <POOL_STATE_ID> <STAKE_POOL_ID> \
    --gas-budget 10000000

sui client call 
    --package 0x0f386fb810c282cbf5c87de51bdee0714ea3160c1eef264ea3a4f962fdcadb50 
    --module launchpad 
    --function end_sale 
   --args 0x3cca1bac7ff6815ab722a0860ec9b2cee913545f957f44d42c683a9bcbc4722e 0xf4f6a91fccc054804f93793f51866a5449a5ff982d7df51024f57928067b526b  
    --gas-budget 10000000


Admin withdraws remaining BITS tokens:

sui client call \
    --package <PACKAGE_ID> \
    --module launchpad \
    --function withdraw_mark \
    --args <POOL_STATE_ID> \
    --gas-budget 10000000