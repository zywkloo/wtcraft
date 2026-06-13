use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TaskStage {
    Planned,
    Executing,
    Verifying,
    Replan,
    Approved,
    Finishing,
    Done,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    Planner,
    Executor,
    Verifier,
    Finisher,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TransitionOwner {
    Role(Role),
}

impl TaskStage {
    /// The role expected to receive or continue work while this stage is set.
    pub const fn responsible_role(self) -> Option<Role> {
        match self {
            Self::Planned | Self::Executing => Some(Role::Executor),
            Self::Verifying => Some(Role::Verifier),
            Self::Replan => Some(Role::Planner),
            Self::Approved | Self::Finishing => Some(Role::Finisher),
            Self::Done => None,
        }
    }

    pub const fn transition_owner(self, next: Self) -> Option<TransitionOwner> {
        match (self, next) {
            (Self::Planned, Self::Executing) | (Self::Executing, Self::Verifying) => {
                Some(TransitionOwner::Role(Role::Executor))
            }
            (Self::Verifying, Self::Replan) => Some(TransitionOwner::Role(Role::Verifier)),
            (Self::Verifying, Self::Approved) => Some(TransitionOwner::Role(Role::Finisher)),
            (Self::Replan, Self::Planned) => Some(TransitionOwner::Role(Role::Planner)),
            (Self::Approved, Self::Finishing) | (Self::Finishing, Self::Done) => {
                Some(TransitionOwner::Role(Role::Finisher))
            }
            _ => None,
        }
    }

    pub const fn allows_transition(self, next: Self) -> bool {
        self.transition_owner(next).is_some()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TaskTransitionError {
    pub from: TaskStage,
    pub to: TaskStage,
}

impl fmt::Display for TaskTransitionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            formatter,
            "illegal task transition: {:?} -> {:?}",
            self.from, self.to
        )
    }
}

impl std::error::Error for TaskTransitionError {}

pub fn validate_task_transition(
    from: TaskStage,
    to: TaskStage,
) -> Result<TransitionOwner, TaskTransitionError> {
    from.transition_owner(to)
        .ok_or(TaskTransitionError { from, to })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_v1_transition_has_the_expected_owner() {
        let legal = [
            (
                TaskStage::Planned,
                TaskStage::Executing,
                TransitionOwner::Role(Role::Executor),
            ),
            (
                TaskStage::Executing,
                TaskStage::Verifying,
                TransitionOwner::Role(Role::Executor),
            ),
            (
                TaskStage::Verifying,
                TaskStage::Replan,
                TransitionOwner::Role(Role::Verifier),
            ),
            (
                TaskStage::Verifying,
                TaskStage::Approved,
                TransitionOwner::Role(Role::Finisher),
            ),
            (
                TaskStage::Replan,
                TaskStage::Planned,
                TransitionOwner::Role(Role::Planner),
            ),
            (
                TaskStage::Approved,
                TaskStage::Finishing,
                TransitionOwner::Role(Role::Finisher),
            ),
            (
                TaskStage::Finishing,
                TaskStage::Done,
                TransitionOwner::Role(Role::Finisher),
            ),
        ];

        for (from, to, owner) in legal {
            assert_eq!(validate_task_transition(from, to), Ok(owner));
        }
    }

    #[test]
    fn done_is_terminal() {
        for next in [
            TaskStage::Planned,
            TaskStage::Executing,
            TaskStage::Verifying,
            TaskStage::Replan,
            TaskStage::Approved,
            TaskStage::Finishing,
            TaskStage::Done,
        ] {
            assert!(!TaskStage::Done.allows_transition(next));
        }
    }

    #[test]
    fn planned_is_handed_to_executor() {
        assert_eq!(TaskStage::Planned.responsible_role(), Some(Role::Executor));
    }
}
