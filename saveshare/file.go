package main

import (
	"fmt"
	"io"
	"os"

	"github.com/pkg/sftp"
)

func downloadFile(sftpClient *sftp.Client, remotePath, localPath string) error {
	remoteFile, err := sftpClient.Open(remotePath)
	if err != nil {
		return fmt.Errorf("error opening remote file: %v: %w", remotePath, err)
	}
	defer remoteFile.Close()

	localFile, err := os.Create(localPath)
	if err != nil {
		return fmt.Errorf("error creating local file: %w", err)
	}
	defer localFile.Close()

	if _, err = io.Copy(localFile, remoteFile); err != nil {
		return fmt.Errorf("error copying file: %w", err)
	}

	fileInfo, err := remoteFile.Stat()
	if err != nil {
		return fmt.Errorf("error getting remote file info: %w", err)
	}

	if err = os.Chtimes(localPath, fileInfo.ModTime(), fileInfo.ModTime()); err != nil {
		return fmt.Errorf("error setting local file mod time: %w", err)
	}

	return nil
}

func uploadFile(sftpClient *sftp.Client, localPath, remotePath string) error {
	localFile, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("error opening local file: %w", err)
	}
	defer localFile.Close()

	remoteFile, err := sftpClient.Create(remotePath)
	if err != nil {
		return fmt.Errorf("error creating remote file: %w", err)
	}
	defer remoteFile.Close()

	if _, err = io.Copy(remoteFile, localFile); err != nil {
		return fmt.Errorf("error copying file: %w", err)
	}

	fileInfo, err := localFile.Stat()
	if err != nil {
		return fmt.Errorf("error getting local file info: %w", err)
	}

	if err = sftpClient.Chtimes(remotePath, fileInfo.ModTime(), fileInfo.ModTime()); err != nil {
		return fmt.Errorf("error setting remote file mod time: %w", err)
	}

	return nil
}
