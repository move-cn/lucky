module lucky::lucky {
    use std::vector;
    use sui::balance::Balance;
    use sui::coin::{Coin, into_balance};
    use sui::object;
    use sui::object::UID;
    use sui::random::Random;
    use sui::transfer::{share_object, public_transfer};


    /// A shared counter.
    public struct Lucky<phantom T> has key {
        id: UID,
        value: Balance<T>,
        rand: vector<u64>
    }

    entry fun send<T>(rand: &Random, in: Coin<T>, nums: u8, ctx: &mut TxContext) {
        let rand = vector::singleton(20);

        let lk = Lucky<T> {
            id: object::new(ctx),
            value: into_balance(in),
            rand
        };
        share_object(lk);
    }

    entry fun claim<T>(lk: &mut Lucky<T>, rand: &Random, ctx: &mut TxContext) {
        let value = 32u64;

        let out = lk.value.split(value).into_coin(ctx);
        public_transfer(out, ctx.sender());
    }
}
