use core::panic;
use std::env;
use std::ffi::OsString;
use std::fs;
use std::os;
use std::path::{Path, PathBuf};

use fs_extra;
use thiserror::Error;

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

#[allow(dead_code)]
#[derive(Debug, Default, Clone, PartialEq)]
enum FileConflictStrategy {
    #[default]
    Skip,
    Panic,
    Backup,
    OverwriteAlways,
    OverwriteIfNewerElsePanic,
    // LaunchMergeTool,
}

#[allow(dead_code)]
#[derive(Debug, Default, Clone, PartialEq)]
enum DirectoryConflictStrategy {
    #[default]
    Skip,
    Panic,
    Backup,
    OverwriteAlways,
    OverwriteIfNewerElsePanic,
    // LaunchMergeToolForDirectory {
    //     tool_name: String,
    //     tool_args: Vec<String>,
    // },
}

#[derive(Debug, Default, Clone)]
enum InstallMethod {
    #[default]
    Symlink,
    Copy,
}

#[derive(Error, Debug)]
pub enum ConfigFileInstallError {
    #[error("Config file source at path {:?} does not exist", .0.to_str())]
    SourceDoesNotExist(OsString),
    #[error("Config file source at path {:?} is a directory", .0.to_str())]
    SourceIsDirectory(OsString),
    #[error("File permissions on {:?} prevented reading metadata", .0.to_str())]
    SourceHasPermissionsIssue(OsString),
    #[error("File permissions on {:?} prevented reading metadata", .0.to_str())]
    DestinationHasPermissionsIssue(OsString),
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

#[derive(Debug, Clone)]
struct ConfigFile {
    src: PathBuf,
    dst: PathBuf,
    conflict_strategy: FileConflictStrategy,
    install_method: InstallMethod,
}

impl ConfigFile {
    fn try_copy(&self) -> Result<(), ConfigFileInstallError> {
        match fs::copy(&self.src, &self.dst) {
            Ok(_) => return Ok(()),
            Err(err) => return Err(ConfigFileInstallError::Other(err.into())),
        }
    }

    fn try_symlink(&self) -> Result<(), ConfigFileInstallError> {
        #[cfg(unix)]
        {
            os::unix::fs::symlink(self.src, self.dst)
        }
        #[cfg(windows)]
        {
            match os::windows::fs::symlink_file(&self.src, &self.dst) {
                Ok(_) => return Ok(()),
                Err(err) => return Err(ConfigFileInstallError::Other(err.into())),
            }
        }
    }

    fn install(&self) -> Result<(), ConfigFileInstallError> {
        if !self.src.exists() {
            return Err(ConfigFileInstallError::SourceDoesNotExist(
                self.src.clone().into_os_string(),
            ));
        }
        if let Ok(src_metadata) = fs::metadata(&self.src) {
            if src_metadata.is_dir() {
                return Err(ConfigFileInstallError::SourceIsDirectory(
                    self.src.clone().into_os_string(),
                ));
            }
        } else {
            return Err(ConfigFileInstallError::SourceHasPermissionsIssue(
                self.src.clone().into_os_string(),
            ));
        }

        fs::create_dir_all(&self.dst.parent().unwrap()).expect("Failed to create parent dir");

        if self.dst.exists() {
            match self.conflict_strategy {
                FileConflictStrategy::Skip => {
                    println!("File already exists and \"skip\" strategy was provided, skipping");
                    return Ok(())
                },
                FileConflictStrategy::Panic => panic!(),
                FileConflictStrategy::Backup => todo!(),
                FileConflictStrategy::OverwriteAlways => self.try_copy(),
                FileConflictStrategy::OverwriteIfNewerElsePanic => todo!(),
                // FileConflictStrategy::LaunchMergeTool => todo!(),
            }
        } else {
            match self.install_method {
                InstallMethod::Symlink => todo!(),
                InstallMethod::Copy => self.try_copy(),
            }
        }
    }
}

#[derive(Error, Debug)]
pub enum ConfigDirectoryInstallError {
    #[error("Config directory source at path {:?} does not exist", .0.to_str())]
    SourceDoesNotExist(OsString),
    #[error("Config directory source at path {:?} is not a directory", .0.to_str())]
    SourceIsFile(OsString),
    #[error("File permissions on {:?} prevented reading metadata", .0.to_str())]
    SourceHasPermissionsIssue(OsString),
    #[error("Config directory destination at path {:?} is not a directory", .0.to_str())]
    DestinationIsFile(OsString),
    #[error("File permissions on {:?} prevented reading metadata", .0.to_str())]
    DestinationHasPermissionsIssue(OsString),
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

#[derive(Debug, Clone)]
struct ConfigDirectory {
    src: PathBuf,
    dst: PathBuf,
    conflict_strategy: DirectoryConflictStrategy,
    install_method: InstallMethod,
}

impl ConfigDirectory {
    fn try_copy_overwrite(&self) -> Result<(), ConfigDirectoryInstallError> {
        let options = fs_extra::dir::CopyOptions::new().overwrite(true);
        match fs_extra::dir::copy(&self.src, &self.dst, &options) {
            Ok(_) => return Ok(()),
            Err(err) => return Err(ConfigDirectoryInstallError::Other(err.into())),
        }
    }

    fn try_copy_skip(&self) -> Result<(), ConfigDirectoryInstallError> {
        let options = fs_extra::dir::CopyOptions::new().skip_exist(true);
        match fs_extra::dir::copy(&self.src, &self.dst, &options) {
            Ok(_) => return Ok(()),
            Err(err) => return Err(ConfigDirectoryInstallError::Other(err.into())),
        }
    }

    fn try_symlink(&self) -> Result<(), ConfigDirectoryInstallError> {
        #[cfg(unix)]
        {
            os::unix::fs::symlink(self.src, self.dst)
        }
        #[cfg(windows)]
        {
            match os::windows::fs::symlink_dir(&self.src, &self.dst) {
                Ok(_) => return Ok(()),
                Err(err) => return Err(ConfigDirectoryInstallError::Other(err.into())),
            }
        }
    }

    fn install(&self) -> Result<(), ConfigDirectoryInstallError> {
        if !self.src.exists() {
            return Err(ConfigDirectoryInstallError::SourceDoesNotExist(
                self.src.clone().into_os_string(),
            ));
        }
        if let Ok(src_metadata) = fs::metadata(&self.src) {
            if src_metadata.is_file() {
                return Err(ConfigDirectoryInstallError::SourceIsFile(
                    self.src.clone().into_os_string(),
                ));
            }
        } else {
            return Err(ConfigDirectoryInstallError::SourceHasPermissionsIssue(
                self.src.clone().into_os_string(),
            ));
        }

        fs::create_dir_all(&self.dst.parent().unwrap()).expect("Failed to create parent dir");

        if self.dst.exists() {
            let dst_metadata = fs::metadata(&self.dst).expect(
                format!(
                    "Failed to read filesystem metadata for path: {:?}",
                    &self.dst
                )
                .as_str(),
            );
            if dst_metadata.is_file() {
                return Err(ConfigDirectoryInstallError::DestinationIsFile(
                    self.dst.clone().into_os_string(),
                ));
            }
            match &self.conflict_strategy {
                DirectoryConflictStrategy::Skip => self.try_copy_skip(),
                DirectoryConflictStrategy::Panic => panic!(),
                DirectoryConflictStrategy::Backup => todo!(),
                DirectoryConflictStrategy::OverwriteAlways => self.try_copy_overwrite(),
                DirectoryConflictStrategy::OverwriteIfNewerElsePanic => todo!(),
                // DirectoryConflictStrategy::LaunchMergeToolForDirectory { tool_name, tool_args } => todo!(),
            }
        } else {
            match self.install_method {
                InstallMethod::Symlink => self.try_symlink(),
                InstallMethod::Copy => self.try_copy_overwrite(),
            }
        }
    }
}

#[derive(Debug, Clone)]
enum ConfigItem {
    File(ConfigFile),
    Directory(ConfigDirectory),
}

impl ConfigItem {
    pub fn install(&self) -> Result<(), String> {
        match self {
            ConfigItem::File(config_file) => match config_file.install() {
                Ok(_) => Ok(()),
                Err(err) => Err(err.to_string()),
            },
            ConfigItem::Directory(config_directory) => match config_directory.install() {
                Ok(_) => Ok(()),
                Err(err) => Err(err.to_string()),
            },
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
    let nvim_cfg = ConfigItem::Directory(ConfigDirectory {
        src: ext_path(&workspace_root, vec!["dotfiles", "nvim"]),
        dst: match env::consts::OS {
            "windows" => ext_path(&user_home, vec!["Appdata", "Local", "nvim"]),
            "macos" | "linux" => ext_path(&user_home, vec![".config", "nvim"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
        install_method: Default::default(),
    });

    // git
    let gitconfig = ConfigItem::File(ConfigFile {
        src: ext_path(&workspace_root, vec!["dotfiles", "git", ".gitconfig"]),
        dst: match env::consts::OS {
            "windows" | "macos" | "linux" => ext_path(&user_home, vec![".gitconfig"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
        install_method: Default::default(),
    });
    let gitignore_global = ConfigItem::File(ConfigFile {
        src: ext_path(
            &workspace_root,
            vec!["dotfiles", "git", ".gitignore.global"],
        ),
        dst: match env::consts::OS {
            "windows" | "macos" | "linux" => ext_path(&user_home, vec![".gitignore.global"]),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: Default::default(),
        install_method: Default::default(),
    });

    // vscode
    let vscode_user_settings = ConfigItem::File(ConfigFile {
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
        install_method: Default::default(),
    });

    // PowerShell
    let pwsh_curr_user_curr_host = ConfigItem::File(ConfigFile {
        src: ext_path(
            &workspace_root,
            vec!["pwsh", "profiles", "current-user-current-host", "Microsoft.PowerShell_profile.ps1"],
        ),
        dst: match env::consts::OS {
            "windows" => ext_path(
                &user_home,
                vec![
                    "Documents",
                    "PowerShell",
                    "Microsoft.PowerShell_profile.ps1",
                ],
            ),
            "macos" | "linux" => todo!(),
            _ => panic!("Unsupported OS"),
        },
        conflict_strategy: FileConflictStrategy::OverwriteAlways,
        install_method: InstallMethod::Copy,
    });

    dbg!(&nvim_cfg);
    dbg!(&gitconfig);
    dbg!(&gitignore_global);
    dbg!(&vscode_user_settings);
    dbg!(&pwsh_curr_user_curr_host);

    let configs = vec![
        // nvim_cfg,
        // gitconfig,
        // gitignore_global,
        // vscode_user_settings,
        pwsh_curr_user_curr_host,
    ];

    for config in configs {
        match config.install() {
            Ok(_) => (),
            Err(err) => {
                eprintln!("{}", err);
            }
        }
    }
}
