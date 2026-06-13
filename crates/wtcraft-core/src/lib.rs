//! Pure governance models for wtcraft.
//!
//! This crate deliberately does not execute Git, launch processes, read
//! terminals, or mutate task/session files.

mod reconciliation;
mod session;
mod task;

pub use reconciliation::{
    reconcile, Alarm, AlarmKind, GitFacts, ReconciliationInput, Severity, TaskFacts,
};
pub use session::{LaunchMode, SessionRecord, SessionState, SessionValidationError};
pub use task::{validate_task_transition, Role, TaskStage, TaskTransitionError, TransitionOwner};
