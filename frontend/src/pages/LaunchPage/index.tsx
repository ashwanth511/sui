import { useState, useEffect } from "react"
import { ConnectButton, useWallet } from '@suiet/wallet-kit'
import { TransactionBlock } from '@mysten/sui.js/transactions'
import { SuiClient } from '@mysten/sui.js/client'
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Brain } from 'lucide-react'
import { Link } from "react-router-dom"
import ReactConfetti from 'react-confetti'
import "@suiet/wallet-kit/style.css";
import './connect-button.css'

const CONTRACT_CONFIG = {
  PACKAGE_ID: "0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a",
  POOL_STATE_ID: "0xa150222cfd213773d39608e9b4e20f769ef68fa4faac4cd9d740043cfa734853",
  TOKEN_TYPE: "0xbc6f1b953c6d60218e39df93e45929898cc1d463f0473163b5ebbb19f535003a::bits::BITS",
  SUI_TYPE: "0x2::sui::SUI",
  STAKE_POOL_ID: "0xfa1af904bdaa1cccd91c27c2614dce6981c3b2220912e06de84e40c92aab346b"
}

export default function LaunchPage(): JSX.Element {
  const { connected, account } = useWallet()
  const wallet = useWallet()
  const [activeTab, setActiveTab] = useState<'buy' | 'stake'>('buy');
  const [amount, setAmount] = useState(0);
  const [stakeAmount, setStakeAmount] = useState(0);
  const [tokenBalance, setTokenBalance] = useState<string>('0');
  const [suiBalance] = useState<string>('0');
  const [showConfetti, setShowConfetti] = useState(false);
  const [lastStakeTime, setLastStakeTime] = useState<number | null>(null);
  const [timeRemaining, setTimeRemaining] = useState<number>(0);
  const [hasStaked, setHasStaked] = useState(false);
  const [stakeInfoId, setStakeInfoId] = useState<string | null>(null);
  const [stakedAmount, setStakedAmount] = useState<string>('0');
  const bitsPerSui = 100;

  interface StakeInfo {
    id: string;
    amount: number;
    timestamp: number;
    status: 'staked' | 'unstaked';
  }

  const [stakeHistory, setStakeHistory] = useState<StakeInfo[]>([]);

  const calculateBits = (suiAmount: number) => {
    return suiAmount * bitsPerSui;
  };

  const fetchBalances = async () => {
    try {
      if (!account?.address) return;

      const client = new SuiClient({
        url: 'https://fullnode.devnet.sui.io:443'
      });

      // Fetch token balance
      const { data: tokenCoins } = await client.getCoins({
        owner: account.address,
        coinType: CONTRACT_CONFIG.TOKEN_TYPE
      });

      // Calculate total token balance
      const totalTokens = tokenCoins.reduce(
        (sum, coin) => sum + BigInt(coin.balance),
        BigInt(0)
      );

      console.log('BITS balance:', {
        totalTokens: totalTokens.toString(),
        inBITS: Number(totalTokens) / 1_000_000_000,
        coins: tokenCoins.map(coin => ({
          id: coin.coinObjectId,
          balance: coin.balance,
          inBITS: Number(coin.balance) / 1_000_000_000
        }))
      });

      setTokenBalance((Number(totalTokens) / 1_000_000_000).toFixed(2));

    } catch (error) {
      console.error('Error fetching balances:', error);
    }
  };

  const fetchStakeInfo = async () => {
    if (!account?.address) return;

    try {
      const client = new SuiClient({
        url: 'https://fullnode.devnet.sui.io:443'
      });

      // Get owned objects of type StakeInfo
      const { data: objects } = await client.getOwnedObjects({
        owner: account.address,
        filter: {
          MatchAll: [
            { StructType: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::StakeInfo` }
          ]
        },
        options: {
          showContent: true,
          showType: true
        }
      });

      // Parse stake info objects
      const stakes = objects
        .filter(obj => obj.data?.objectId) // Filter out objects with undefined id
        .map(obj => {
          const fields = (obj.data?.content as any)?.fields;
          return {
            id: obj.data!.objectId, // Safe to use ! here because of filter
            amount: Number(fields?.amount) / 1_000_000_000,
            timestamp: Number(fields?.last_update_time),
            status: 'staked' as const // Type assertion to literal type
          };
        });

      setStakeHistory(stakes);
      console.log('Stake history:', stakes);

    } catch (error) {
      console.error('Error fetching stake info:', error);
    }
  };

  // @ts-expect-error - Required for future functionality
  const checkSuiBalance = async () => {
    if (!account?.address) return false;

    try {
      const client = new SuiClient({
        url: 'https://fullnode.devnet.sui.io:443'
      });

      // Get SUI coins
      const { data: suiCoins } = await client.getCoins({
        owner: account.address,
        coinType: '0x2::sui::SUI'
      });

      // Calculate total SUI balance
      const totalSui = suiCoins.reduce(
        (sum, coin) => sum + BigInt(coin.balance),
        BigInt(0)
      );

      console.log('SUI balance:', {
        totalSui: totalSui.toString(),
        inSUI: Number(totalSui) / 1_000_000_000
      });

      // Check if we have at least 0.1 SUI for gas
      return totalSui >= BigInt(100_000_000);
    } catch (error) {
      console.error('Error checking SUI balance:', error);
      return false;
    }
  };

  const REWARD_WAIT_TIME = 60000; // 1 minute in milliseconds

  // Update timer
  useEffect(() => {
    const interval = setInterval(() => {
      if (lastStakeTime) {
        const elapsed = Date.now() - lastStakeTime;
        const remaining = Math.max(0, REWARD_WAIT_TIME - elapsed);
        setTimeRemaining(remaining);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [lastStakeTime]);

  useEffect(() => {
    if (connected && account?.address) {
      fetchBalances();
      fetchStakeInfo();
    } else {
  
      setTokenBalance('0');
      setStakeInfoId(null);
      setStakedAmount('0');
      setHasStaked(false);
    }
  }, [connected, account?.address]);

  // Format remaining time
  const formatTimeRemaining = (ms: number) => {
    const minutes = Math.floor(ms / 60000);
    const seconds = Math.floor((ms % 60000) / 1000);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };


  

  const buyTokens = async (amount: number) => {
    try {
      if (!account?.address) {
        throw new Error('Wallet not connected');
      }

      console.log('Using wallet address:', account.address);

    

      const tx = new TransactionBlock();
      
      const amountInMist = amount * 1_000_000_000;
      
      const [coin] = tx.splitCoins(tx.gas, [tx.pure(amountInMist)]);
      
      tx.moveCall({
        target: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::buy_tokens`,
        arguments: [
          tx.object(CONTRACT_CONFIG.POOL_STATE_ID),
          coin,
          tx.pure(amountInMist)
        ]
      });

      tx.transferObjects([coin], tx.pure(account.address));

      console.log('Executing transaction with account:', account.address);
      
      const response = await wallet.signAndExecuteTransaction({
        transaction: tx as unknown as { toJSON(): Promise<string> }
      });

      console.log('Transaction successful:', response);
      
      // Show confetti and refresh balances
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 5000);
      await fetchBalances();
      
    } catch (error) {
      console.error('Transaction failed:', error);
      throw error;
    }
  }

 
  const stakeTokens = async () => {
    try {
      if (!account?.address || !stakeAmount || !wallet) return;

      console.log('Using wallet address:', account.address);

      const client = new SuiClient({
        url: 'https://fullnode.devnet.sui.io:443'
      });

      // Get SUI coins for gas
      const { data: suiCoins } = await client.getCoins({
        owner: account.address,
        coinType: '0x2::sui::SUI'
      });

      if (!suiCoins || suiCoins.length === 0) {
        console.error('No SUI coins found for gas');
        return;
      }

      // Find a SUI coin with sufficient balance for gas
      const totalSuiBalance = suiCoins.reduce((sum, coin) => sum + BigInt(coin.balance), BigInt(0));
      console.log('Total SUI balance:', totalSuiBalance.toString());

      if (totalSuiBalance < BigInt(20000000)) {
        console.error('Insufficient SUI balance for gas');
        return;
      }

      const gasCoin = suiCoins[0];
      console.log('Using SUI coin for gas:', gasCoin);

      const amountInMist = Math.floor(stakeAmount * 1_000_000_000);
      console.log('Amount to stake in MIST:', amountInMist);

      // Get user's BITS coins
      const { data: bitsCoins } = await client.getCoins({
        owner: account.address,
        coinType: CONTRACT_CONFIG.TOKEN_TYPE
      });

      if (!bitsCoins || bitsCoins.length === 0) {
        console.error('No BITS coins found');
        return;
      }

      // Calculate total balance
      const totalBalance = bitsCoins.reduce((sum, coin) => sum + BigInt(coin.balance), BigInt(0));
      console.log('Total balance:', totalBalance.toString(), 'Required:', amountInMist);

      if (totalBalance < BigInt(amountInMist)) {
        console.error('Insufficient total balance');
        return;
      }

      // Find a coin with sufficient balance
      let coinToUse = bitsCoins.find(coin => BigInt(coin.balance) >= BigInt(amountInMist));
      
      if (!coinToUse) {
        // If no single coin has enough, we need to merge coins in the same transaction
        if (bitsCoins.length > 1) {
          console.log('No single coin has sufficient balance, will merge in transaction');
          
          const tx = new TransactionBlock();
          tx.setGasBudget(20000000);
          tx.setGasPayment([{
            objectId: gasCoin.coinObjectId,
            digest: gasCoin.digest,
            version: gasCoin.version
          }]);

          // Merge all BITS coins
          const primaryCoin = tx.object(bitsCoins[0].coinObjectId);
          for (let i = 1; i < bitsCoins.length; i++) {
            tx.mergeCoins(primaryCoin, [tx.object(bitsCoins[i].coinObjectId)]);
          }

          // Call stake_tokens with the merged coin
          tx.moveCall({
            target: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::stake_tokens`,
            arguments: [
              tx.object(CONTRACT_CONFIG.STAKE_POOL_ID),
              primaryCoin,
              tx.pure(amountInMist),
              tx.object('0x6')
            ]
          });

          const response = await wallet.signAndExecuteTransaction({
            transaction: tx as unknown as { toJSON(): Promise<string> }
          });

          console.log('Transaction successful:', response);
        } else {
          console.error('No coin with sufficient balance found');
          return;
        }
      } else {
        // Use the single coin that has enough balance
        console.log('Using single coin for staking:', {
          id: coinToUse.coinObjectId,
          balance: coinToUse.balance,
          stakeAmount: amountInMist
        });

        const tx = new TransactionBlock();
        
        // Set gas budget and payment
        tx.setGasBudget(20000000);
        tx.setGasPayment([{
          objectId: gasCoin.coinObjectId,
          digest: gasCoin.digest,
          version: gasCoin.version
        }]);
       
        // Call stake_tokens directly with the coin
        tx.moveCall({
          target: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::stake_tokens`,
          arguments: [
            tx.object(CONTRACT_CONFIG.STAKE_POOL_ID),
            tx.object(coinToUse.coinObjectId),
            tx.pure(amountInMist),
            tx.object('0x6')
          ]
        });

        const response = await wallet.signAndExecuteTransaction({
          transaction: tx as unknown as { toJSON(): Promise<string> }
        });

        console.log('Transaction successful:', response);
      }
      
      // Update state after successful stake
      setLastStakeTime(Date.now());
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 5000);
      
      // Fetch updated balances and stake info
      await fetchBalances();
      await fetchStakeInfo();

    } catch (error) {
      console.error('Staking failed:', error);
    }
  };

  const claimRewards = async () => {
    try {
      if (!account?.address || !stakeInfoId || timeRemaining > 0) return;

      const tx = new TransactionBlock();

      tx.moveCall({
        target: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::claim_rewards`,
        arguments: [
          tx.object(CONTRACT_CONFIG.STAKE_POOL_ID),
          tx.object(stakeInfoId),
          tx.object('0x6') 
        ]
      });

      const response = await wallet.signAndExecuteTransaction({
        transaction: tx as unknown as { toJSON(): Promise<string> }
      });

          console.log('Rewards claimed:', response);
      
      // Fetch updated balances and stake info
      await fetchBalances();
      await fetchStakeInfo();

    } catch (error) {
      console.error('Claiming rewards failed:', error);
    }
  };

  const unstakeTokens = async (stakeId: string) => {
    try {
      if (!account?.address) return;
  
      const stakeInfo = stakeHistory.find(s => s.id === stakeId);
      if (!stakeInfo) return;
  
      const tx = new TransactionBlock();
  
      tx.moveCall({
        target: `${CONTRACT_CONFIG.PACKAGE_ID}::launchpad::unstake_tokens`,
        arguments: [
          tx.object(CONTRACT_CONFIG.STAKE_POOL_ID),
          tx.object(stakeId),
          tx.pure(stakeInfo.amount * 1_000_000_000), // Convert to MIST
        ]
      });
  
      const response = await wallet.signAndExecuteTransaction({
        transaction: tx as unknown as { toJSON(): Promise<string> }
      });
  
      console.log('Unstaking successful:', response);
  
      setStakeHistory(prev => prev.map(stake => 
        stake.id === stakeId 
          ? { ...stake, status: 'unstaked' }
          : stake
      ));
  
      await fetchBalances();
      await fetchStakeInfo();
  
    } catch (error) {
      console.error('Unstaking failed:', error);
    }
  };
  
  const StakeHistoryTable = () => (
    <div className="mt-8">
      <h3 className="text-2xl font-bold mb-4 text-gradient bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-pink-600">Stake History</h3>
      <div className="overflow-x-auto rounded-lg shadow-xl">
        <table className="min-w-full bg-gradient-to-b from-gray-900 to-gray-800 text-gray-100">
          <thead className="bg-gradient-to-r from-purple-500/10 to-pink-500/10">
            <tr>
              <th className="px-6 py-4 border-b border-gray-700 font-semibold">Amount (BITS)</th>
              <th className="px-6 py-4 border-b border-gray-700 font-semibold">Date</th>
              <th className="px-6 py-4 border-b border-gray-700 font-semibold">Status</th>
              <th className="px-6 py-4 border-b border-gray-700 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {stakeHistory.map((stake) => (
              <tr key={stake.id} className="hover:bg-gray-800/50 transition-colors">
                <td className="px-6 py-4 text-center font-medium">
                  <span className="text-purple-400">{stake.amount}</span>
                </td>
                <td className="px-6 py-4 text-center text-gray-300">
                  {new Date(stake.timestamp).toLocaleString()}
                </td>
                <td className="px-6 py-4 text-center">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    stake.status === 'staked' 
                      ? 'bg-green-500/20 text-green-400 border border-green-500/30' 
                      : 'bg-purple-500/20 text-purple-400 border border-purple-500/30'
                  }`}>
                    {stake.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-center">
                  {stake.status === 'staked' && (
                    <button
                      onClick={() => unstakeTokens(stake.id)}
                      className="bg-gradient-to-r from-red-500 to-pink-500 text-white px-4 py-2 rounded-lg font-medium hover:from-red-600 hover:to-pink-600 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-pink-500/25"
                    >
                      Unstake
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
      {showConfetti && <ReactConfetti />}
      
      <header className="container mx-auto px-4 py-6 flex justify-between items-center">
        <Link to="/" className="flex items-center space-x-2">
          <Brain className="w-8 h-8" />
          <span className="text-2xl font-bold">AIAgentLaunch</span>
        </Link>
        
        <div className="flex items-center space-x-4">
          {connected && (
            <div className="flex items-center space-x-4 mr-4">
              <div className="text-sm">
                <span className="text-gray-400">SUI Balance:</span> {suiBalance} SUI
              </div>
              <div className="text-sm">
                <span className="text-gray-400">BITS Balance:</span> {tokenBalance} BITS
              </div>
            </div>
          )}
          <ConnectButton />
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="flex justify-center space-x-4 mb-8">
          <Button
            variant={activeTab === 'buy' ? "default" : "outline"}
            onClick={() => setActiveTab('buy')}
          >
            Buy Tokens
          </Button>
          <Button
            variant={activeTab === 'stake' ? "default" : "outline"}
            onClick={() => setActiveTab('stake')}
          >
            Stake Tokens
          </Button>
        </div>

        {activeTab === 'buy' ? (
          <div className="max-w-md mx-auto">
            <Card>
              <CardHeader>
                <CardTitle>Buy BITS Tokens</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Amount (SUI)
                    </label>
                    <input
                      type="number"
                      value={amount}
                      onChange={(e) => setAmount(Number(e.target.value))}
                      className="w-full p-2 bg-gray-700 rounded"
                      min="0"
                      step="0.1"
                    />
                  </div>
                  <div className="text-sm text-gray-400">
                    You will receive: {calculateBits(amount)} BITS
                  </div>
                  <Button
                    className="w-full"
                    onClick={() => buyTokens(amount)}
                    disabled={!connected || amount <= 0}
                  >
                    Buy Tokens
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : (
          <div className="max-w-md mx-auto">
            <Card>
              <CardHeader>
                <CardTitle>Stake BITS Tokens</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {!hasStaked ? (
                    <>
                      <div>
                        <label className="block text-sm font-medium mb-2">
                          Amount (BITS)
                        </label>
                        <input
                          type="number"
                          value={stakeAmount}
                          onChange={(e) => setStakeAmount(Number(e.target.value))}
                          className="w-full p-2 bg-gray-700 rounded"
                          min="0"
                          step="0.1"
                        />
                      </div>
                      <Button
                        className="w-full"
                        onClick={stakeTokens}
                        disabled={!connected || stakeAmount <= 0}
                      >
                        Stake Tokens
                      </Button>
                    </>
                  ) : (
                    <div className="space-y-4">
                      <div className="text-sm text-gray-400">
                        Staked Amount: {Number(stakedAmount) / 1_000_000_000} BITS
                      </div>
                      <div className="text-sm text-gray-400 mb-2">
                        Time until rewards: {formatTimeRemaining(timeRemaining)}
                      </div>
                      <Button
                        className="w-full mb-2"
                        onClick={claimRewards}
                        disabled={timeRemaining > 0}
                      >
                        Claim Rewards
                      </Button>
                      <Button
                        className="w-full"
                        onClick={() => unstakeTokens(stakeInfoId as string)}
                        variant="destructive"
                      >
                        Unstake Tokens
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
            <StakeHistoryTable />
          </div>
        )}
      </main>
    </div>
  );
}
