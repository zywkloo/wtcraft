use crate::{Role, SessionState, TaskStage};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum AlarmKind {
    IllegalTransition,
    Bypass,
    VerificationUnproven,
    RoleMismatch,
    StaleExecution,
    Uncontracted,
    ContractTampered,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Severity {
    Warning,
    Violation,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Alarm {
    pub kind: AlarmKind,
    pub severity: Severity,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TaskFacts {
    pub stage: TaskStage,
    pub role: Option<Role>,
    pub verification_passed: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct GitFacts {
    pub has_changes: bool,
    pub recent_activity: bool,
    pub contract_tampered: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReconciliationInput {
    pub task: Option<TaskFacts>,
    pub previous_stage: Option<TaskStage>,
    pub session: Option<SessionState>,
    pub git: GitFacts,
}

pub fn reconcile(input: ReconciliationInput) -> Vec<Alarm> {
    let mut alarms = Vec::new();

    let Some(task) = input.task else {
        if input.session.is_some() || input.git.has_changes {
            alarms.push(alarm(AlarmKind::Uncontracted));
        }
        return alarms;
    };

    if let Some(previous) = input.previous_stage {
        if previous != task.stage && !previous.allows_transition(task.stage) {
            alarms.push(alarm(AlarmKind::IllegalTransition));
        }
    }

    if matches!(task.stage, TaskStage::Planned | TaskStage::Replan)
        && (input.git.has_changes || input.session.is_some_and(SessionState::is_live))
    {
        alarms.push(alarm(AlarmKind::Bypass));
    }

    if matches!(
        task.stage,
        TaskStage::Approved | TaskStage::Finishing | TaskStage::Done
    ) && !task.verification_passed
    {
        alarms.push(alarm(AlarmKind::VerificationUnproven));
    }

    if task.role != task.stage.responsible_role() {
        alarms.push(alarm(AlarmKind::RoleMismatch));
    }

    if task.stage == TaskStage::Executing
        && !input.session.is_some_and(SessionState::is_live)
        && !input.git.recent_activity
    {
        alarms.push(alarm(AlarmKind::StaleExecution));
    }

    if input.git.contract_tampered {
        alarms.push(alarm(AlarmKind::ContractTampered));
    }

    alarms
}

const fn alarm(kind: AlarmKind) -> Alarm {
    let severity = match kind {
        AlarmKind::IllegalTransition
        | AlarmKind::VerificationUnproven
        | AlarmKind::ContractTampered => Severity::Violation,
        AlarmKind::Bypass
        | AlarmKind::RoleMismatch
        | AlarmKind::StaleExecution
        | AlarmKind::Uncontracted => Severity::Warning,
    };
    Alarm { kind, severity }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn task(stage: TaskStage) -> TaskFacts {
        TaskFacts {
            stage,
            role: stage.responsible_role(),
            verification_passed: false,
        }
    }

    #[test]
    fn executing_with_live_session_is_consistent() {
        let alarms = reconcile(ReconciliationInput {
            task: Some(task(TaskStage::Executing)),
            previous_stage: Some(TaskStage::Planned),
            session: Some(SessionState::Running),
            git: GitFacts::default(),
        });

        assert!(alarms.is_empty());
    }

    #[test]
    fn alarms_have_deterministic_protocol_order() {
        let alarms = reconcile(ReconciliationInput {
            task: Some(TaskFacts {
                stage: TaskStage::Done,
                role: Some(Role::Executor),
                verification_passed: false,
            }),
            previous_stage: Some(TaskStage::Planned),
            session: None,
            git: GitFacts {
                contract_tampered: true,
                ..GitFacts::default()
            },
        });

        assert_eq!(
            alarms,
            vec![
                alarm(AlarmKind::IllegalTransition),
                alarm(AlarmKind::VerificationUnproven),
                alarm(AlarmKind::RoleMismatch),
                alarm(AlarmKind::ContractTampered),
            ]
        );
    }

    #[test]
    fn work_without_a_contract_is_reported() {
        let alarms = reconcile(ReconciliationInput {
            task: None,
            previous_stage: None,
            session: Some(SessionState::Running),
            git: GitFacts::default(),
        });

        assert_eq!(alarms, vec![alarm(AlarmKind::Uncontracted)]);
    }
}
