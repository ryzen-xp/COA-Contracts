use starknet::ContractAddress;

#[derive(Drop, Serde, Clone, Introspect)]
#[dojo::model]
pub struct CurrencyBalance {
    #[key]
    pub player_id: u32,
    pub currency_type: felt252,
    pub amount: u32,
}

#[generate_trait]
pub impl CurrencyBalanceImpl of CurrencyBalanceTrait {
    fn earn_currency(ref self: CurrencyBalance, amount: u32) {
        self.amount += amount;
    }

    fn spend_currency(ref self: CurrencyBalance, amount: u32) {
        assert(self.amount >= amount, 'Insufficient balance');
        self.amount -= amount;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait};
    use super::{CurrencyBalance, CurrencyBalanceTrait};

    #[test]
    fn test_earn_currency() {
        let mut balance = CurrencyBalance { player_id: 1, currency_type: 'STK'.into(), amount: 0 };

        balance.earn_currency(100);
        assert(balance.amount == 100, 'Balance should be 100');

        balance.earn_currency(50);
        assert(balance.amount == 150, 'Balance should be 150');
    }

    #[test]
    fn test_spend_currency() {
        let mut balance = CurrencyBalance {
            player_id: 1, currency_type: 'ETH'.into(), amount: 100,
        };

        balance.spend_currency(50);
        assert(balance.amount == 50, 'Balance should be 50');

        #[should_panic(expected = 'Insufficient balance')]
        balance.spend_currency(100);
    }

    #[test]
    #[should_panic]
    fn test_revert_if_balance_less_than_amout() {
        let mut balance = CurrencyBalance { player_id: 1, currency_type: 'COA'.into(), amount: 10 };

        balance.spend_currency(200);
    }
}
