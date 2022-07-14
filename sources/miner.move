module carrara::miner {
    use AptosFramework::Coin;
    use carrara::payroll;

    friend carrara::quarry;

    /// An account that has staked tokens into a [Quarry].
    struct Miner<phantom TCollateral> has store {
        /// [TokenAccount] to hold the [Miner]'s staked LP tokens.
        balance: Coin::Coin<TCollateral>,

        /// Stores the amount of tokens that the [Miner] may claim.
        /// Whenever the [Miner] claims tokens, this is reset to 0.
        rewards_earned: u64,

        /// A checkpoint of the [Quarry]'s reward tokens paid per staked token.
        ///
        /// When the [Miner] is initialized, this number starts at 0.
        /// On the first [quarry_mine::stake_tokens], the [Quarry]#update_rewards_and_miner
        /// method is called, which updates this checkpoint to the current quarry value.
        ///
        /// On a [quarry_mine::claim_rewards], the difference in checkpoints is used to calculate
        /// the amount of tokens owed.
        rewards_per_token_paid: u128,
    }

    /// Gets the balance of a [Miner].
    /// @newcode
    public fun balance<TCollateral>(miner: &Miner<TCollateral>): u64 {
        Coin::value<TCollateral>(&miner.balance)
    }

    /// Deposits collateral into the [Miner].
    /// @newcode
    public(friend) fun stake_collateral<TCollateral>(miner: &mut Miner<TCollateral>, source: Coin::Coin<TCollateral>) {
        Coin::merge<TCollateral>(&mut miner.balance, source)
    }

    /// Withdraws collateral from the [Miner].
    /// @newcode
    public(friend) fun withdraw_collateral<TCollateral>(miner: &mut Miner<TCollateral>, amount: u64): Coin::Coin<TCollateral> {
        Coin::extract<TCollateral>(&mut miner.balance, amount)
    }

    public(friend) fun update_rewards_earned<TCollateral>(
        miner: &mut Miner<TCollateral>,
        payroll: &payroll::Payroll,
        current_ts: u64,
        quarry_rewards_per_token_stored: u128
    ) {
        let updated_rewards_earned = payroll::calculate_rewards_earned(
            payroll,
            current_ts,
            balance(miner),
            miner.rewards_per_token_paid,
            miner.rewards_earned,
        );

        // Update miner struct
        miner.rewards_earned = updated_rewards_earned;
        miner.rewards_per_token_paid = quarry_rewards_per_token_stored;
    }
}
