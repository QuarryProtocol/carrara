/// Handles distribution of rewards.

module carrara::quarry {
    use AptosFramework::Coin;
    use carrara::payroll;
    use carrara::rewarder;
    use carrara::miner::{Self, Miner};

    /// A pool which distributes tokens to its [Miner]s.
    struct Quarry<phantom TCollateral> has key {
        /// Timestamp when quarry rewards cease
        famine_ts: u64,
        /// Timestamp of last checkpoint
        last_update_ts: u64,
        /// Rewards per token stored in the quarry
        rewards_per_token_stored: u128,
        /// Amount of rewards distributed to the quarry per year.
        annual_rewards_rate: u64,
        /// Rewards shared allocated to this quarry
        rewards_share: u64,

        /// Total number of tokens deposited into the quarry.
        total_tokens_deposited: u64,
        /// Number of [Miner]s.
        num_miners: u64,

        /// Allows disbursing rewards from the [rewarder::Rewarder].
        disburse_cap: rewarder::DisburseCapability,
    }

    /// Updates the quarry by synchronizing its rewards rate with the rewarder.
    fun update_rewards_internal<TReward, TCollateral>(
        quarry: &mut Quarry<TCollateral>,
        current_ts: u64,
        rewarder: &rewarder::Rewarder<TReward>,
        payroll: &payroll::Payroll,
    ) {
        let updated_rewards_per_token_stored = payroll::calculate_reward_per_token(payroll, current_ts);
        // Update quarry struct
        quarry.rewards_per_token_stored = updated_rewards_per_token_stored;
        quarry.annual_rewards_rate =
            rewarder::compute_quarry_annual_rewards_rate(rewarder, quarry.rewards_share);
        quarry.last_update_ts = payroll::last_time_reward_applicable(payroll, current_ts);
    }

    /// Create a [Payroll] from a [Quarry].
    fun into_payroll<TCollateral>(quarry: &Quarry<TCollateral>): payroll::Payroll {
        payroll::new(
            quarry.famine_ts,
            quarry.last_update_ts,
            quarry.annual_rewards_rate,
            quarry.rewards_per_token_stored,
            quarry.total_tokens_deposited,
        )
    }

    /// Updates the quarry and miner with the latest info.
    /// <https://github.com/Synthetixio/synthetix/blob/aeee6b2c82588681e1f99202663346098d1866ac/contracts/StakingRewards.sol#L158>
    fun update_rewards_and_miner<TReward, TCollateral>(
        quarry: &mut Quarry<TCollateral>,
        miner: &mut Miner<TCollateral>,
        rewarder: &rewarder::Rewarder<TReward>,
        current_ts: u64,
    ) {
        let payroll = into_payroll(quarry);
        update_rewards_internal(quarry, current_ts, rewarder, &payroll);
        miner::update_rewards_earned(
            miner,
            &payroll,
            current_ts,
            quarry.rewards_per_token_stored
        );
    }

    /// Processes a [StakeAction] for a [Miner],
    fun process_stake_internal<TReward, TCollateral>(
        quarry: &mut Quarry<TCollateral>,
        current_ts: u64,
        rewarder: &rewarder::Rewarder<TReward>,
        miner: &mut Miner<TCollateral>,
        source: Coin::Coin<TCollateral>,
    ) {
        update_rewards_and_miner(quarry, miner, rewarder, current_ts);

        // old logic:
        // miner.balance = miner.balance + amount;
        let amount = Coin::value(&source);
        miner::stake_collateral(miner, source);

        quarry.total_tokens_deposited = quarry.total_tokens_deposited + amount;
    }

    /// Processes a withdrawal for a [Miner],
    fun process_withdraw_internal<TReward, TCollateral>(
        quarry: &mut Quarry<TCollateral>,
        current_ts: u64,
        rewarder: &rewarder::Rewarder<TReward>,
        miner: &mut miner::Miner<TCollateral>,
        amount: u64,
    ): Coin::Coin<TCollateral> {
        update_rewards_and_miner(quarry, miner, rewarder, current_ts);

        // old logic:
        // miner.balance = miner.balance - amount;
        let coin = miner::withdraw_collateral(miner, amount);

        quarry.total_tokens_deposited = quarry.total_tokens_deposited - amount;
        coin
    }
}
