/// Defines the Rewarder.

module carrara::rewarder {
    use AptosFramework::Coin;

    /// Invalid quarry rewards share
    const EINVALID_REWARDS_SHARE: u64 = 1;

    /// Controls token rewards distribution to all [Quarry]s.
    /// The [Rewarder] is also the [quarry_mint_wrapper::Minter] registered to the [quarry_mint_wrapper::MintWrapper].
    struct Rewarder<phantom TReward> has key {
        /// Amount of reward tokens distributed per day
        annual_rewards_rate: u64,
        /// Total amount of rewards shares allocated to [Quarry]s
        total_rewards_shares: u64,
        /// Holds the rewards to be distributed.
        rewards: Coin::Coin<TReward>,

        /// Claim fees are placed in this account.
        claim_fees: Coin::Coin<TReward>,
        /// Maximum amount of tokens to send to the Quarry DAO on each claim,
        /// in terms of milliBPS. 1,000 milliBPS = 1 BPS = 0.01%
        /// This is stored on the [Rewarder] to ensure that the fee will
        /// not exceed this in the future.
        max_claim_fee_millibps: u64,

        /// If true, all instructions on the [Rewarder] are paused other than [quarry_mine::unpause].
        is_paused: bool,
    }

    /// Capability representing the ability to disburse rewards from the [Rewarder].
    /// This should only be held by the [Quarry].
    struct DisburseCapability has store {
        rewarder: address,
    }

    struct SetRatesCapability has copy, drop, store {
        rewarder: address
    }

    struct CreateQuarryCapability has copy, drop, store {
        rewarder: address
    }

    struct AllocateSharesCapability has copy, drop, store {
        rewarder: address
    }

    /// Authority allowed to pause a [Rewarder].
    struct PauseCapability has copy, drop, store {
        rewarder: address
    }

    /// Sets whether the [Rewarder] is paused.
    public fun set_paused<TReward>(
        pause_capability: &PauseCapability,
        value: bool
    ) acquires Rewarder {
        let rewarder = borrow_global_mut<Rewarder<TReward>>(pause_capability.rewarder);
        rewarder.is_paused = value;
    }

    /// Container type for rewarder-related capabilities.
    struct Operator has key, store {
        set_rates_cap: SetRatesCapability,
        create_quarry_cap: CreateQuarryCapability,
        allocate_shares_cap: AllocateSharesCapability,
        pause_cap: PauseCapability,
    }

    /// Creates a new [Operator] for the given [Rewarder].
    fun new_operator(rewarder: address): Operator {
        Operator {
            set_rates_cap: SetRatesCapability {
                rewarder
            },
            create_quarry_cap: CreateQuarryCapability {
                rewarder
            },
            allocate_shares_cap: AllocateSharesCapability {
                rewarder
            },
            pause_cap: PauseCapability {
                rewarder
            },
        }
    }

    /// Computes the amount of rewards a [crate::Quarry] should receive, annualized.
    /// This should be run only after `total_rewards_shares` has been set.
    /// Do not call this directly. Use `compute_quarry_annual_rewards_rate`.
    fun compute_quarry_annual_rewards_rate_unsafe<TReward>(rewarder: &Rewarder<TReward>, quarry_rewards_share: u64): u64 {
        let quarry_annual_rewards_rate = (rewarder.annual_rewards_rate as u128)
            * (quarry_rewards_share as u128)
            / (rewarder.total_rewards_shares as u128);

        (quarry_annual_rewards_rate as u64)
    }

    /// Computes the amount of rewards a [crate::Quarry] should receive, annualized.
    /// This should be run only after `total_rewards_shares` has been set.
    public fun compute_quarry_annual_rewards_rate<TReward>(rewarder: &Rewarder<TReward>, quarry_rewards_share: u64): u64 {
        assert!(
            quarry_rewards_share <= rewarder.total_rewards_shares,
            EINVALID_REWARDS_SHARE
        );

        // no rewards if:
        if (rewarder.total_rewards_shares == 0 // no shares
            || rewarder.annual_rewards_rate == 0 // rewards rate is zero
            || quarry_rewards_share == 0)
        // quarry has no share
        {
            0
        } else {
            compute_quarry_annual_rewards_rate_unsafe(rewarder, quarry_rewards_share)
        }
    }

}