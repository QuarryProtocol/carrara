module carrara::cmp {
    public fun min(a: u64, b: u64): u64 {
        if (a < b) {
            a
        } else {
            b
        }
    }

    public fun max(a: u64, b: u64): u64 {
        if (a > b) {
            a
        } else {
            b
        }
    }
}
