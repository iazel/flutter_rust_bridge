use flutter_rust_bridge::{frb, DartFnFuture, DartOpaque};
use tokio::sync::Mutex;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

lazy_static::lazy_static! {
    static ref MUTEX: Mutex<()> = Mutex::new(());
}

pub async fn run_with_lock(
    f: impl Fn() -> DartFnFuture<Result<(), DartOpaque>>
) -> Result<(), DartOpaque> {
    let _lock = MUTEX.lock().await;
    f().await
}
