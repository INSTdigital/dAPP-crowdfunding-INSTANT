#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();

#[derive(TopEncode, TopDecode, TypeAbi, PartialEq, Clone, Copy, Debug)]
pub enum Status {
    FundingPeriod,
    Successful,
    Failed,
}

#[elrond_wasm::contract]
pub trait Crowdfunding {
    #[init]
    fn init(&self, target: BigUint, minimum_deposit: BigUint, maximum_deposit: BigUint, deadline: u64) {
        require!(minimum_deposit <= maximum_deposit, "Minimum deposit must be less than maximum deposit");

        require!(minimum_deposit > 0, "Minimum deposit must be more than 0");
        self.minimum_deposit().set(&minimum_deposit);

        require!(maximum_deposit > 0, "Maximum deposit must be more than 0");
        self.maximum_deposit().set(&maximum_deposit);

        require!(target >= 0, "Target must be more than or equal to 0");
        self.target().set(&target);

        require!(
            deadline > self.get_current_time(),
            "Deadline can't be in the past"
        );
        self.deadline().set(&deadline);
    }

    #[endpoint]
    #[payable("*")]
    fn fund(
        &self,
        #[payment_amount] payment: BigUint,
    ) -> SCResult<()> {
        require!(self.status() == Status::FundingPeriod, "cannot fund after deadline");
        require!(payment >= self.minimum_deposit().get(), "cannot fund under minimum");
        require!(payment <= self.maximum_deposit().get(), "cannot fund over maximum deposit");

        let caller = self.blockchain().get_caller();
        self.deposit(&caller).update(|deposit| *deposit += payment);
        Ok(())
    }

    #[view]
    fn status(&self) -> Status {
        if self.get_current_time() < self.deadline().get() {
            Status::FundingPeriod
        } else if self.get_current_funds() >= self.target().get() {
            Status::Successful
        } else {
            Status::Failed
        }
    }

    #[view(getCurrentFunds)]
    fn get_current_funds(&self) -> BigUint {
        self.blockchain().get_sc_balance(&TokenIdentifier::egld(), 0)
    }

    #[endpoint]
    fn claim(&self) -> SCResult<()> {
        match self.status() {
            Status::FundingPeriod => sc_panic!("cannot claim before deadline"),
            Status::Successful => {
                let caller = self.blockchain().get_caller();

                require!(
                    caller == self.blockchain().get_owner_address(),
                    "only owner can claim successful funding"
                );

                let sc_balance = self.get_current_funds();

                self.send()
                    .direct(&caller, &TokenIdentifier::egld(), 0, &sc_balance, b"claim");
                Ok(())
            },
            Status::Failed => {
                let caller = self.blockchain().get_caller();
                let deposit = self.deposit(&caller).get();

                if deposit > 0 {
                    self.deposit(&caller).clear();
                    self.send()
                        .direct(&caller, &TokenIdentifier::egld(), 0, &deposit, b"claim");
                }
                Ok(())
            },
        }
    }

    // private

    fn get_current_time(&self) -> u64 {
        self.blockchain().get_block_timestamp()
    }

    // storage

    #[view(getTarget)]
    #[storage_mapper("target")]
    fn target(&self) -> SingleValueMapper<BigUint>;

    #[view(minimumDeposit)]
    #[storage_mapper("minimumDeposit")]
    fn minimum_deposit(&self) -> SingleValueMapper<BigUint>;

    #[view(maximumDeposit)]
    #[storage_mapper("maximumDeposit")]
    fn maximum_deposit(&self) -> SingleValueMapper<BigUint>;

    #[view(getDeadline)]
    #[storage_mapper("deadline")]
    fn deadline(&self) -> SingleValueMapper<u64>;

    #[view(getDeposit)]
    #[storage_mapper("deposit")]
    fn deposit(&self, donor: &ManagedAddress) -> SingleValueMapper<BigUint>;
}
