use core::num::traits::zero::Zero;

#[derive(Drop, Serde, Copy, Clone)]
#[dojo::model]
pub struct Quest {
    #[key]
    pub id: u32,
    pub description: felt252,
    pub goal: u32,
    pub reward: u32,
    pub category: u8,
    pub is_set: bool,
}

#[generate_trait]
pub impl QuestImpl of QuestTrait {
    fn new(id: u32, description: felt252, goal: u32, reward: u32, category: u8) -> Quest {
        Quest { id, description, goal, reward, category, is_set: true }
    }

    fn is_completed(self: @Quest, progress: u32) -> bool {
        progress >= *self.goal
    }
}

#[generate_trait]
pub impl QuestAssert of AssertTrait {
    #[inline(always)]
    fn assert_exists(self: Quest) {
        assert(self.is_non_zero(), 'QUEST_NOT_FOUND');
    }
}

pub impl ZeroableQuestTrait of Zero<Quest> {
    #[inline(always)]
    fn zero() -> Quest {
        Quest { id: 0, description: 0, goal: 0, reward: 0, category: 0, is_set: false }
    }

    #[inline(always)]
    fn is_zero(self: @Quest) -> bool {
        !(*self.is_set)
    }

    #[inline(always)]
    fn is_non_zero(self: @Quest) -> bool {
        *self.is_set
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_quest() {
        let q = QuestImpl::new(1, 'daily_kill', 10, 100, 2);
        assert(q.id == 1, 'Invalid id');
        assert(q.description == 'daily_kill', 'Invalid description');
        assert(q.goal == 10, 'Invalid goal');
        assert(q.reward == 100, 'Invalid reward');
        assert(q.category == 2, 'Invalid category');
        assert(q.is_set, 'Should be set');
    }

    #[test]
    fn test_quest_completion() {
        let q = QuestImpl::new(1, 'daily_kill', 10, 100, 2);
        assert(QuestImpl::is_completed(@q, 5) == false, 'Should not be complete');
        assert(QuestImpl::is_completed(@q, 10) == true, 'Should be complete');
        assert(QuestImpl::is_completed(@q, 15) == true, 'Should be complete');
    }

    #[test]
    fn test_zero_quest() {
        let q = ZeroableQuestTrait::zero();
        assert(q.id == 0, 'Zero id mismatch');
        assert(ZeroableQuestTrait::is_zero(@q), 'Should be zero');
        assert(!ZeroableQuestTrait::is_non_zero(@q), 'Should not be non-zero');
    }

    #[test]
    fn test_assert_exists() {
        let q = QuestImpl::new(2, 'collect', 5, 50, 1);
        QuestAssert::assert_exists(q);
    }
}
