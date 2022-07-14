/// Calculates token distribution rates.

module carrara::payroll {
    use carrara::cmp;

    /// Number of seconds in a year.
    const SECONDS_PER_YEAR: u128 = 86400 * 365;

    /// Precision multiplier that `rewards_per_token_stored` uses.
    /// Currently this is 15 decimals.
    const PRECISION_MULTIPLIER: u64 = 1000000000000000;

    /// Invalid timestamp.
    const EINVALID_TIMESTAMP: u64 = 1;

    /// Not enough tokens.
    const ENOT_ENOUGH_TOKENS: u64 = 2;

    /// Calculator for amount of tokens to pay out.
    struct Payroll has copy, drop {
        /// Timestamp of when rewards should end.
        famine_ts: u64,
        /// Timestamp of the last update.
        last_checkpoint_ts: u64,

        /// Amount of tokens to issue per year.
        annual_rewards_rate: u64,

        /// Amount of tokens to issue per staked token,
        /// multiplied by u64::MAX for precision.
        rewards_per_token_stored: u128,

        /// Total number of tokens deposited into the [Quarry].
        total_tokens_deposited: u64,
    }

    /// Creates a new [Payroll].
    public fun new(
        famine_ts: u64,
        last_checkpoint_ts: u64,
        annual_rewards_rate: u64,
        rewards_per_token_stored: u128,
        total_tokens_deposited: u64,
    ): Payroll {
        Payroll {
            famine_ts,
            last_checkpoint_ts,
            annual_rewards_rate,
            rewards_per_token_stored,
            total_tokens_deposited,
        }
    }

    /// Calculates the amount of rewards to pay out for each staked token.
    /// <https://github.com/Synthetixio/synthetix/blob/4b9b2ee09b38638de6fe1c38dbe4255a11ebed86/contracts/StakingRewards.sol#L62>
    fun calculate_reward_per_token_unsafe(payroll: &Payroll, current_ts: u64): u128 {
        if (payroll.total_tokens_deposited == 0) {
            payroll.rewards_per_token_stored
        } else {
            let time_worked = compute_time_worked(payroll, current_ts);

            let reward: u128 = (time_worked as u128)
                * (PRECISION_MULTIPLIER as u128)
                / SECONDS_PER_YEAR
                * (payroll.annual_rewards_rate as u128)
                / (payroll.total_tokens_deposited as u128);

            payroll.rewards_per_token_stored + reward
        }
    }

    /// Calculates the amount of rewards to pay for each staked token, performing safety checks.
    public fun calculate_reward_per_token(payroll: &Payroll, current_ts: u64): u128 {
        assert!(current_ts >= payroll.last_checkpoint_ts, EINVALID_TIMESTAMP);
        calculate_reward_per_token_unsafe(payroll, current_ts)
    }

    /// Calculates the amount of rewards earned for the given number of staked tokens.
    /// https://github.com/Synthetixio/synthetix/blob/4b9b2ee09b38638de6fe1c38dbe4255a11ebed86/contracts/StakingRewards.sol#L72
    fun calculate_rewards_earned_unsafe(
        payroll: &Payroll,
        current_ts: u64,
        tokens_deposited: u64,
        rewards_per_token_paid: u128,
        rewards_earned: u64,
    ): u64 {
        let net_new_rewards_per_token = calculate_reward_per_token_unsafe(payroll, current_ts) - rewards_per_token_paid;
        (((tokens_deposited as u128)
            * net_new_rewards_per_token
            / (PRECISION_MULTIPLIER as u128)) as u64)
            + rewards_earned
    }

    /// Calculates the amount of rewards earned for the given number of staked tokens, with safety checks.
    /// <https://github.com/Synthetixio/synthetix/blob/4b9b2ee09b38638de6fe1c38dbe4255a11ebed86/contracts/StakingRewards.sol#L72>
    public fun calculate_rewards_earned(
        payroll: &Payroll,
        current_ts: u64,
        tokens_deposited: u64,
        rewards_per_token_paid: u128,
        rewards_earned: u64,
    ): u64 {
        assert!(
            tokens_deposited <= payroll.total_tokens_deposited,
            ENOT_ENOUGH_TOKENS
        );
        assert!(current_ts >= payroll.last_checkpoint_ts, EINVALID_TIMESTAMP);
        calculate_rewards_earned_unsafe(
            payroll,
            current_ts,
            tokens_deposited,
            rewards_per_token_paid,
            rewards_earned,
        )
    }

    /// Gets the latest time rewards were being distributed.
    public fun last_time_reward_applicable(payroll: &Payroll, current_ts: u64): u64 {
        cmp::min(current_ts, payroll.famine_ts)
    }

    /// Calculates the amount of seconds the [Payroll] should have applied rewards for.
    fun compute_time_worked(payroll: &Payroll, current_ts: u64): u64 {
        cmp::max(
            0,
            last_time_reward_applicable(payroll, current_ts) - payroll.last_checkpoint_ts,
        )
    }

}