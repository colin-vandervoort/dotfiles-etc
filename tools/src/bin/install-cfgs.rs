use std::env;
use std::fs;
use std::path::{Path, PathBuf};

fn get_workspace_root() -> Result<PathBuf, &'static str> {
    if let Ok(current_dir) = env::var("CARGO_MANIFEST_DIR") {
        Path::new(&current_dir)
            .ancestors()
            .skip(1)
            .find_map(|path| {
                if path.join("Cargo.toml").exists() {
                    Some(path.to_path_buf())
                } else {
                    None
                }
            })
            .ok_or("Cargo.toml not found in any ancestor of CARGO_MANIFEST_DIR")
    } else {
        Err("CARGO_MANIFEST_DIR not set")
    }
}

#[derive(Debug, Default, Clone)]
enum ConflictStrategy {
    #[default]
    Skip,
    Panic,
    Backup,
    Overwrite,
}

#[derive(Debug, Clone)]
struct ItemMeta {
    src: PathBuf,
    dst: PathBuf,
    conflict_strategy: ConflictStrategy,
}

#[derive(Default)]
enum SyncMethod {
    #[default]
    Symlink,
    Copy,
}

#[derive(Debug, Clone)]
enum Config {
    File(ItemMeta),
    Directory(ItemMeta),
}

impl Config {
    fn install(&self, sync_method: SyncMethod) {
        match (sync_method, self) {
            (
                SyncMethod::Copy,
                Config::File(ItemMeta {
                    src,
                    dst,
                    conflict_strategy,
                }),
            ) => {
                fs::copy(src, dst).expect("Failed to copy file");
            }
            (
                SyncMethod::Symlink,
                Config::File(ItemMeta {
                    src,
                    dst,
                    conflict_strategy,
                }),
            ) => {
                todo!();
            }
            (
                SyncMethod::Copy,
                Config::Directory(ItemMeta {
                    src,
                    dst,
                    conflict_strategy,
                }),
            ) => {
                todo!();
            }
            (
                SyncMethod::Symlink,
                Config::Directory(ItemMeta {
                    src,
                    dst,
                    conflict_strategy,
                }),
            ) => {
                todo!();
            }
        }
    }
}

fn ext_path<A: AsRef<Path>, B: AsRef<Path>>(base: &A, components: Vec<B>) -> PathBuf {
    components
        .iter()
        .fold(base.as_ref().to_path_buf(), |acc, x| acc.join(x))
}

fn main() {
    let workspace_root: PathBuf = get_workspace_root().unwrap();
    let user_home: PathBuf = match env::consts::OS {
        "windows" => env::var("USERPROFILE").unwrap().into(),
        "macos" | "linux" => env::var("HOME").unwrap().into(),
        _ => panic!("Unsupported OS"),
    };

    // nvim
    let nvim_cfg = Config::Directory(ItemMeta {
        src: ext_path(&workspace_root, vec!["dotfiles", "nvim"]),
        dst: match env::consts::OS {
            "windows" => ext_path(&user_home, vec!["Appdata", "Local", "nvim"]),
            "macos" | "linux" => ext_path(&user_home, vec![".config", "nvim"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
    });

    // git
    let gitconfig = Config::File(ItemMeta {
        src: ext_path(&workspace_root, vec!["dotfiles", "git", ".gitconfig"]),
        dst: match env::consts::OS {
            "windows" | "macos" | "linux" => ext_path(&user_home, vec![".gitconfig"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
    });
    let gitignore_global = Config::File(ItemMeta {
        src: ext_path(
            &workspace_root,
            vec!["dotfiles", "git", ".gitignore.global"],
        ),
        dst: match env::consts::OS {
            "windows" | "macos" | "linux" => ext_path(&user_home, vec![".gitignore.global"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
    });

    // vscode
    let vscode_user_settings = Config::File(ItemMeta {
        src: ext_path(&workspace_root, vec!["dotfiles", "vscode", "settings.json"]),
        dst: match env::consts::OS {
            "windows" => ext_path(
                &user_home,
                vec!["AppData", "Roaming", "Code", "User", "settings.json"],
            ),
            "macos" | "linux" => {
                ext_path(&user_home, vec![".config", "Code", "User", "settings.json"])
            }
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
    });

    dbg!(&nvim_cfg);
    dbg!(&gitconfig);
    dbg!(&gitignore_global);
    dbg!(&vscode_user_settings);

    let configs = vec![
        // nvim_cfg,
        gitconfig,
        gitignore_global,
        // vscode_user_settings,
    ];

    for config in configs {
        config.install(SyncMethod::Copy);
    }
}
