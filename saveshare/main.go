package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/pkg/sftp"
	"github.com/rs/zerolog"
	"golang.org/x/crypto/ssh"
)

var (
	logger  = zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout, TimeFormat: time.RFC3339}).With().Timestamp().Logger().Level(zerolog.InfoLevel)
	logfile = ""
	slash   = string(os.PathSeparator)
)

func main() {
	configDir, err := os.UserConfigDir()
	if err != nil {
		logger.Fatal().Err(err).Msg("Failed to get user config directory")
	}

	configDir = filepath.Clean(configDir + slash + "FactoryGameSaveShare")
	logfile = configDir + slash + "log.txt"

	if err = os.MkdirAll(configDir, 0o755); err != nil {
		logger.Fatal().Err(err).Msg("Failed to create config directory")
	}

	// Create the log file if it doesn't already exist.
	if _, err = os.Stat(logfile); os.IsNotExist(err) {
		if _, err = os.Create(logfile); err != nil {
			logger.Fatal().Err(err).Msg("Failed to create log file")
		}
	}

	logFile, err := os.OpenFile(logfile, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0o600)
	if err != nil {
		logger.Fatal().Err(err).Msg("Failed to open log file")
	}

	// Replace the default logger with one that writes a file and to the console.
	logger = zerolog.New(zerolog.MultiLevelWriter(zerolog.ConsoleWriter{Out: os.Stdout, TimeFormat: time.RFC3339}, logFile)).With().Timestamp().Logger().Level(zerolog.InfoLevel)

	logger.Info().Msg("Satisfactory Save Share Client v1.8.2")
	logger.Info().Msg("https://github.com/wolveix/satisfactory-server/saveshare")
	logger.Info().Msg("Initializing config...")

	cfg, err := NewConfig(configDir)
	if err != nil {
		logger.Fatal().Err(err).Msg("Failed to load config")
		return
	}

	if cfg.SessionName == "" {
		fmt.Printf("Please input your session name: ")

		if _, err = fmt.Scanln(&cfg.SessionName); err != nil {
			fmt.Printf("\nFailed to read session name: %v\n", err)
			return
		}

		if err = cfg.Save(); err != nil {
			logger.Fatal().Err(err).Msg("Failed to save config")
		}

		cfg.BlueprintPath = cfg.gamePath + slash + "blueprints" + slash + cfg.SessionName
	}

	if cfg.ServerAddress == "" {
		fmt.Printf("Please input your server address: ")

		if _, err = fmt.Scanln(&cfg.ServerAddress); err != nil {
			fmt.Printf("\nFailed to read server address: %v\n", err)
			return
		}

		if err = cfg.Save(); err != nil {
			logger.Fatal().Err(err).Msg("Failed to save config")
		}
	}

	if cfg.ServerPassword == "" {
		fmt.Printf("Please input your server password: ")

		if _, err = fmt.Scanln(&cfg.ServerPassword); err != nil {
			fmt.Printf("\nFailed to read server password: %v\n", err)
			return
		}

		if err = cfg.Save(); err != nil {
			logger.Fatal().Err(err).Msg("Failed to save config")
		}
	}

	logger.Info().Msg("Config loaded successfully!")

	// Establish an SSH connection to the server.
	sshConfig := &ssh.ClientConfig{
		User: "saveshare",
		Auth: []ssh.AuthMethod{
			ssh.Password(cfg.ServerPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	sshClient, err := ssh.Dial("tcp", cfg.ServerAddress, sshConfig)
	if err != nil {
		logger.Fatal().Err(err).Msg("Error connecting to server")
	}
	defer sshClient.Close()

	// Establish an SFTP session.
	sftpClient, err := sftp.NewClient(sshClient)
	if err != nil {
		logger.Fatal().Err(err).Msg("Error creating SFTP client")
		return
	}
	defer sftpClient.Close()

	logger.Info().Msg("Connected to server!")

	remotePath := "upload/" + cfg.SessionName

	// Create the remote directories if they don't already exist.
	if err = sftpClient.MkdirAll(remotePath + "/blueprints"); err != nil {
		fmt.Printf("Error creating remote blueprints directory: %v\n", err)
		return
	}

	if err = sftpClient.MkdirAll(remotePath + "/saves"); err != nil {
		fmt.Printf("Error creating remote saves directory: %v\n", err)
		return
	}

	for {
		logger.Info().Msg("Syncing...")

		if err = syncLocalUpdates(sftpClient, cfg.BlueprintPath, remotePath+"/blueprints", ""); err != nil {
			logger.Error().Err(err).Msg("Unexpected error while checking for blueprint updates")
		}

		if err = syncLocalUpdates(sftpClient, cfg.SavePath, remotePath+"/saves", cfg.SessionName); err != nil {
			logger.Error().Err(err).Msg("Unexpected error while checking for save updates")
		}

		if err = syncRemoteUpdates(sftpClient, cfg.BlueprintPath, remotePath+"/blueprints"); err != nil {
			logger.Error().Err(err).Msg("Unexpected error while checking for blueprint updates")
		}

		if err = syncRemoteUpdates(sftpClient, cfg.SavePath, remotePath+"/saves"); err != nil {
			logger.Error().Err(err).Msg("Unexpected error while checking for save updates")
		}

		time.Sleep(2 * time.Minute)
	}
}

// syncLocalUpdates walks through the local directories and syncs files to/from the remote server
func syncLocalUpdates(sftpClient *sftp.Client, localPath string, remotePath string, sessionName string) error {
	return filepath.Walk(localPath, func(localFilePath string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		remoteFilePath := remotePath + "/" + info.Name()

		// Save files are named like: "SESSIONNAME_autosave_0.sav".
		if sessionName != "" {
			if !strings.HasPrefix(info.Name(), sessionName) {
				return nil
			}
		}

		// Check the file exists on the remote server.
		remoteFile, err := sftpClient.Stat(remoteFilePath)
		if err != nil {
			if os.IsNotExist(err) {
				logger.Info().Msg("Uploading " + localFilePath + " to " + remoteFilePath)
				return uploadFile(sftpClient, localFilePath, remoteFilePath)
			} else {
				return fmt.Errorf("error checking remote file: %w", err)
			}
		}

		// Compare local and remote file timestamps.
		localModTime := info.ModTime().Truncate(1 * time.Second)
		remoteModTime := remoteFile.ModTime().Truncate(1 * time.Second)

		if localModTime == remoteModTime {
			return nil
		}

		if localModTime.After(remoteModTime) {
			// Local file is newer, so upload it.
			logger.Info().Msg("Uploading " + localFilePath + " to " + remoteFilePath)
			return uploadFile(sftpClient, localFilePath, remoteFilePath)
		} else {
			// Remote file is newer, so download it.
			logger.Info().Msg("Downloading " + remoteFilePath + " to " + localFilePath)
			return downloadFile(sftpClient, remoteFilePath, localFilePath)
		}
	})
}

func syncRemoteUpdates(sftpClient *sftp.Client, localPath string, remotePath string) error {
	// Get a list of files and directories from the remote directory.
	remoteFiles, err := sftpClient.ReadDir(remotePath)
	if err != nil {
		return fmt.Errorf("error reading remote directory: %w", err)
	}

	// Iterate through remote files and directories.
	for _, remoteFile := range remoteFiles {
		if remoteFile.IsDir() {
			return nil
		}

		localFilePath := localPath + slash + remoteFile.Name()
		remoteFilePath := remotePath + "/" + remoteFile.Name()

		// Check if the file exists locally.
		localFile, err := os.Stat(localFilePath)
		if err != nil {
			if os.IsNotExist(err) {
				// Download the remote file.
				logger.Info().Msg("Downloading " + remoteFilePath + " to " + localFilePath)
				if err = downloadFile(sftpClient, remoteFilePath, localFilePath); err != nil {
					return err
				}

				continue
			}

			return fmt.Errorf("error checking local file: %w", err)
		}

		// Compare remote and local file timestamps.
		localModTime := localFile.ModTime().Truncate(1 * time.Second)
		remoteModTime := remoteFile.ModTime().Truncate(1 * time.Second)

		// Compare timestamps and synchronize as needed.
		if localModTime == remoteModTime {
			continue
		}

		if remoteModTime.After(localModTime) {
			// Remote file is newer, download it.
			logger.Info().Msg("Downloading " + remoteFilePath + " to " + localFilePath)
			if err = downloadFile(sftpClient, remoteFilePath, localFilePath); err != nil {
				return err
			}
		} else {
			// Local file is newer, upload it.
			logger.Info().Msg("Uploading " + localFilePath + " to " + remoteFilePath)
			if err = uploadFile(sftpClient, localFilePath, remoteFilePath); err != nil {
				return err
			}
		}
	}

	return nil
}
