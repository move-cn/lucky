module lucky::lucky {
    use std::vector;
    use sui::balance::Balance;
    use sui::coin::{Coin, into_balance};
    use sui::object;
    use sui::object::UID;
    use sui::random;
    use sui::random::Random;
    use sui::transfer::{share_object, public_transfer};
    use sui::vec_map;
    use sui::vec_map::VecMap;
    #[test_only]
    use std::debug::print;
    #[test_only]
    use sui::test_scenario;


    /// A shared counter.
    public struct Lucky<phantom T> has key {
        id: UID,
        value: Balance<T>,
        rand: vector<u64>,
        claim_address:VecMap<address,u64>
    }

    entry fun send<T>(rand: &Random, in: Coin<T>, nums: u8, ctx: &mut TxContext) {
        let in_amt = in.value();
        let rand = get_rand_vec(rand, nums, in_amt, ctx);
        let lk = Lucky<T> {
            id: object::new(ctx),
            value: into_balance(in),
            rand,
            claim_address:vec_map::empty()
        };
        share_object(lk);
    }

    entry fun claim<T>(lk: &mut Lucky<T>, rand: &Random, ctx: &mut TxContext) {

        assert!(!lk.claim_address.contains(&ctx.sender()), 0x2);

        let mut gen = random::new_generator(rand, ctx);
        gen.shuffle(&mut lk.rand);
        let rand_amt = lk.rand.pop_back();
        let out = lk.value.split(rand_amt).into_coin(ctx);
        public_transfer(out, ctx.sender());
        lk.claim_address.insert(ctx.sender(),rand_amt);

    }


    fun get_rand_vec(rand: &Random, nums: u8, amt: u64, ctx: &mut TxContext): vector<u64> {
        let mut gen = random::new_generator(rand, ctx);
        let mut i = 0u8;
        let mut total = 0u64;
        let mut vec = vector::empty<u64>();
        while (i < nums) {
            let rand_num = gen.generate_u64_in_range(100, 1000000u64);
            total = total + rand_num;
            vec.push_back(rand_num);
            i = i + 1;
        };

        let mut vec2 = vector::empty<u64>();
        let mut total_amt = 0u64;
        while (i != 0) {
            if (i == 1) {
                vector::pop_back(&mut vec);
                let sca_num = amt - total_amt;
                vec2.push_back(sca_num);
            }else {
                let num = vector::pop_back(&mut vec);
                let sca_num = num * amt / total ;
                vec2.push_back(sca_num);
                total_amt = total_amt + sca_num;
            };
            i = i - 1;
        };

        vector::destroy_empty(vec);

        vec2
    }


    #[test]
    fun test_get_rand_vec() {
        let address = @0x0;

        let mut sce = test_scenario::begin(address);
        {
            let ctx = test_scenario::ctx(&mut sce);

            random::create_for_testing(ctx);
        };


        sce.next_tx(address);
        {

            let in_amt = 1000000;

            let rand = test_scenario::take_shared<Random>(&mut sce);
            let ctx = test_scenario::ctx(&mut sce);

            let mut vec = get_rand_vec(&rand, 100, in_amt, ctx);

            let len = vector::length(&vec);
            let mut i = 0u64;
            let mut  total_amt = 0u64;
            while (i < len) {
                let amt = vector::pop_back(&mut vec);
                total_amt = total_amt + amt;
                print(&amt);
                i = i + 1;
            };

            test_scenario::return_shared(rand);

            assert!(in_amt == total_amt, 0x1);

            print(&total_amt);
        };


        test_scenario::end(sce);
    }
}
