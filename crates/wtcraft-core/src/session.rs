use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LaunchMode {
    Interactive,
    Headless,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SessionState {
    Starting,
    Running,
    Waiting,
    Idle,
    Exited,
    Lost,
    Failed,
}

impl SessionState {
    pub const fn is_live(self) -> bool {
        matches!(
            self,
            Self::Starting | Self::Running | Self::Waiting | Self::Idle
        )
    }

    pub const fn allows_transition(self, next: Self) -> bool {
        matches!(
            (self, next),
            (Self::Starting, Self::Running | Self::Failed | Self::Lost)
                | (
                    Self::Running,
                    Self::Waiting | Self::Idle | Self::Exited | Self::Lost
                )
                | (
                    Self::Waiting,
                    Self::Running | Self::Idle | Self::Exited | Self::Lost
                )
                | (
                    Self::Idle,
                    Self::Running | Self::Waiting | Self::Exited | Self::Lost
                )
                | (Self::Failed | Self::Exited | Self::Lost, Self::Starting)
        )
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SessionRecord {
    pub schema_version: u32,
    pub session_id: String,
    pub worktree: String,
    pub provider: String,
    pub launch_mode: LaunchMode,
    pub state: SessionState,
    pub pid: Option<u32>,
    pub process_started_at: Option<String>,
    pub started_at: String,
    pub last_active_at: Option<String>,
    pub exited_at: Option<String>,
    pub exit_code: Option<i32>,
    pub terminal: Option<String>,
    pub terminal_session_id: Option<String>,
    pub log_path: Option<String>,
    pub summary: Option<String>,
}

impl SessionRecord {
    pub fn validate(&self) -> Result<(), SessionValidationError> {
        if self.schema_version != 1 {
            return Err(SessionValidationError::UnsupportedSchema(
                self.schema_version,
            ));
        }

        if matches!(
            self.state,
            SessionState::Running | SessionState::Waiting | SessionState::Idle
        ) && (self.pid.is_none() || self.process_started_at.is_none())
        {
            return Err(SessionValidationError::MissingProcessIdentity);
        }

        Ok(())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SessionValidationError {
    UnsupportedSchema(u32),
    MissingProcessIdentity,
}

impl fmt::Display for SessionValidationError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedSchema(version) => {
                write!(formatter, "unsupported session schema version: {version}")
            }
            Self::MissingProcessIdentity => {
                write!(formatter, "live session is missing exact process identity")
            }
        }
    }
}

impl std::error::Error for SessionValidationError {}

#[cfg(test)]
mod tests {
    use super::*;

    fn record(state: SessionState) -> SessionRecord {
        SessionRecord {
            schema_version: 1,
            session_id: "session-1".into(),
            worktree: "/repo/worktrees/feat/task".into(),
            provider: "codex".into(),
            launch_mode: LaunchMode::Headless,
            state,
            pid: Some(42),
            process_started_at: Some("2026-06-13T18:32:10Z".into()),
            started_at: "2026-06-13T18:32:10Z".into(),
            last_active_at: None,
            exited_at: None,
            exit_code: None,
            terminal: None,
            terminal_session_id: None,
            log_path: None,
            summary: None,
        }
    }

    #[test]
    fn running_session_requires_exact_process_identity() {
        let mut session = record(SessionState::Running);
        session.process_started_at = None;

        assert_eq!(
            session.validate(),
            Err(SessionValidationError::MissingProcessIdentity)
        );
    }

    #[test]
    fn unknown_json_fields_are_ignored() {
        let value = serde_json::json!({
            "schema_version": 1,
            "session_id": "session-1",
            "worktree": "/repo/worktrees/feat/task",
            "provider": "codex",
            "launch_mode": "headless",
            "state": "failed",
            "pid": null,
            "process_started_at": null,
            "started_at": "2026-06-13T18:32:10Z",
            "last_active_at": null,
            "exited_at": null,
            "exit_code": null,
            "terminal": null,
            "terminal_session_id": null,
            "log_path": null,
            "summary": null,
            "future_optional_field": true
        });

        let session: SessionRecord = serde_json::from_value(value).unwrap();
        assert_eq!(session.state, SessionState::Failed);
    }

    #[test]
    fn replacement_requires_a_terminal_or_lost_state() {
        for state in [
            SessionState::Failed,
            SessionState::Exited,
            SessionState::Lost,
        ] {
            assert!(state.allows_transition(SessionState::Starting));
        }
        assert!(!SessionState::Running.allows_transition(SessionState::Starting));
    }
}
