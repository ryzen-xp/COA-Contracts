use core::fmt::{Display, Formatter, Error};

#[derive(Drop, Serde)]
#[dojo::model]
pub struct Car {
    #[key]
    id: felt252,
    model: ByteArray,
    speed: felt252,
    player_id: Option<felt252>,
}

#[generate_trait]
impl CarImpl of CarTrait {
    fn create_car(id: felt252, model: ByteArray, speed: felt252) -> Car {
        Car { id, model, speed, player_id: Option::None }
    }

    fn assign_car_to_player(ref self: Car, player_id: felt252) {
        assert!(self.player_id.is_none(), "The car is already assigned to a player");

        self.player_id = Option::Some(player_id);
    }
}

impl CarDisplay of Display<Car> {
    fn fmt(self: @Car, ref f: Formatter) -> Result<(), Error> {
        let id = *self.id;
        let model = self.model;
        let speed = *self.speed;
        let mut player_id = 0;

        if let Option::Some(player_id_stored) = *self.player_id {
            player_id = player_id_stored;
        }

        write!(f, "=== Car Details ===\n")?;
        write!(f, "ID: {}\n", id)?;
        write!(f, "Model: {}\n", model)?;
        write!(f, "Speed: {}\n", speed)?;
        write!(f, "Player ID: {}\n", player_id)?;
        write!(f, "=================\n")?;
        Result::Ok(())
    }
}

#[cfg(test)]
mod tests {
    use core::fmt::{Display, Formatter, Error};
    use super::{Car, CarTrait};

    #[test]
    fn test_create_car() {
        let id = 1;
        let model = "Ferrari";
        let speed = 200;

        let car = CarTrait::create_car(id, model.clone(), speed);

        assert!(car.id == id, "Car ID is not correct");
        assert!(car.model == model, "Car model is not correct");
        assert!(car.speed == speed, "Car speed is not correct");
    }

    #[test]
    fn test_assign_car_to_player() {
        let mut car = Car { id: 1, model: "Ferrari", speed: 200, player_id: Option::None };

        let player_id = 1;
        car.assign_car_to_player(player_id);

        assert!(car.player_id == Option::Some(player_id), "Player ID is not correct");
    }

    #[test]
    #[should_panic(expected: ("The car is already assigned to a player",))]
    fn test_unsuccessful_assign_car_to_multiple_players() {
        let mut car = Car { id: 1, model: "Ferrari", speed: 200, player_id: Option::None };

        let first_player_id = 1;
        car.assign_car_to_player(first_player_id);

        assert!(
            car.player_id == Option::Some(first_player_id),
            "Player ID after first assignment is incorrect",
        );

        let second_player_id = 2;
        car.assign_car_to_player(second_player_id);
    }

    #[test]
    fn test_car_display_details() {
        let mut car = Car { id: 1, model: "Ferrari", speed: 200, player_id: Option::None };

        let player_id = 1;
        car.assign_car_to_player(player_id);

        let details = format!("{}", car);

        let expected_details = "=== Car Details ===\n"
            + "ID: 1\n"
            + "Model: Ferrari\n"
            + "Speed: 200\n"
            + "Player ID: 1\n"
            + "=================\n";

        println!("Generated Details:\n{}", details);
        println!("Expected Details:\n{}", expected_details);

        assert_eq!(details, expected_details, "Car details do not match the expected output");
    }
}
