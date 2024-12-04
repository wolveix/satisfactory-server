package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type Config struct {
	gamePath       string
	path           string
	BlueprintPath  string `yaml:"blueprintPath"`
	SavePath       string `yaml:"savePath"`
	ServerAddress  string `yaml:"serverAddress"`
	ServerPassword string `yaml:"serverPassword"`
	SessionName    string `yaml:"sessionName"`
}

func NewConfig(configDir string) (*Config, error) {
	cfg := Config{
		path: configDir + slash + "config.yml",
	}

	// If the file doesn't exist, create an empty file.
	if _, err := os.Stat(cfg.path); os.IsNotExist(err) {
		if _, err = os.Create(cfg.path); err != nil {
			return nil, fmt.Errorf("could not create config file: %w", err)
		}
	}

	yamlData, err := os.ReadFile(cfg.path)
	if err != nil {
		return nil, fmt.Errorf("could not read config file: %w", err)
	}

	if err = yaml.Unmarshal(yamlData, &cfg); err != nil {
		return nil, fmt.Errorf("could not unmarshal config file: %w", err)
	}

	// Populate the blueprint and save paths.
	appDataPath, err := os.UserCacheDir()
	if err != nil {
		return nil, fmt.Errorf("could not get appdata path: %w", err)
	}

	cfg.gamePath = appDataPath + slash + "FactoryGame" + slash + "Saved" + slash + "SaveGames" + slash

	if cfg.SessionName != "" {
		cfg.BlueprintPath = cfg.gamePath + "blueprints" + slash + cfg.SessionName
	}

	if _, err = os.Stat(cfg.gamePath); os.IsNotExist(err) {
		return nil, fmt.Errorf("game path does not exist: %w", err)
	}

	// Determine the save path.
	if err = filepath.Walk(cfg.gamePath, func(path string, info os.FileInfo, err error) error {
		if info == nil {
			return errors.New("path does not exist")
		}

		if info.IsDir() {
			if cfg.SavePath == "" && path != cfg.gamePath {
				cfg.SavePath = path
			}
			return nil
		}

		return nil
	}); err != nil {
		return nil, fmt.Errorf("could not walk over path: %w", err)
	}

	if cfg.SavePath == "" {
		return nil, fmt.Errorf("could not find save path")
	}

	return &cfg, nil
}

func (c *Config) Save() error {
	yamlData, err := yaml.Marshal(c)
	if err != nil {
		return fmt.Errorf("could not marshal config file: %w", err)
	}

	if err = os.WriteFile(c.path, yamlData, 0o644); err != nil {
		return fmt.Errorf("could not write config file: %w", err)
	}

	return nil
}
