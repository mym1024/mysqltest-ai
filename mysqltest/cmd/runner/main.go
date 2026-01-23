package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// AppConfig represents config.json structure
type AppConfig struct {
	Paths struct {
		YaoTestDir   string `json:"yao_test_dir"`
		YaoBaseSrc   string `json:"yao_base_src"`
		MysqlTestSrc string `json:"mysqltest_src"`
	} `json:"paths"`
	Database struct {
		Host string `json:"host"`
		Port int    `json:"port"`
	} `json:"database"`
}

// Config holds the command line arguments
type Config struct {
	Quiet         bool
	TestSet       string
	TestPat       string
	Mode          string // "record" or "test"
	DisableReboot bool
	ConfigFile    string
}

func main() {
	config := parseFlags()

	if !config.Quiet {
		fmt.Println("Starting MySQLtest Runner...")
		fmt.Printf("Args: %+v\n", config)
	}

	// Load AppConfig
	appConfig, err := loadAppConfig(config.ConfigFile)
	if err != nil {
		log.Fatalf("Failed to load config file: %v", err)
	}
	if !config.Quiet {
		fmt.Printf("Loaded Config: %+v\n", appConfig)
	}

	// Prepare Environment Variables based on AppConfig
	env := os.Environ()
	env = append(env, fmt.Sprintf("YAO_TEST_DIR=%s", appConfig.Paths.YaoTestDir))
	env = append(env, fmt.Sprintf("YAO_BASE_SRC=%s", appConfig.Paths.YaoBaseSrc))
	env = append(env, fmt.Sprintf("MYSQLTEST_SRC=%s", appConfig.Paths.MysqlTestSrc))
	env = append(env, fmt.Sprintf("OBMYSQL_MS0=%s", appConfig.Database.Host))
	env = append(env, fmt.Sprintf("OBMYSQL_PORT=%d", appConfig.Database.Port))

	// 1. Setup Environment (Shell)
	if err := runStep("Setup Environment", "sh", []string{"scripts/setup_env.sh"}, env); err != nil {
		log.Fatalf("Setup environment failed: %v", err)
	}

	// 2. Deploy Cluster (Python 2)
	// Only deploy/reboot if disable-reboot is false
	if !config.DisableReboot {
		if err := runStep("Deploy Cluster", "python2", []string{"scripts/deploy_cluster.py"}, env); err != nil {
			log.Fatalf("Deploy cluster failed: %v", err)
		}
	} else {
		if !config.Quiet {
			fmt.Println("Skipping cluster reboot (disable-reboot=true)")
		}
	}

	// 3. Run Test (Python 2)
	testArgs := []string{"scripts/run_test.py"}
	if config.Quiet {
		testArgs = append(testArgs, "--quiet")
	}
	if config.TestSet != "" {
		testArgs = append(testArgs, "--testset", config.TestSet)
	}
	if config.TestPat != "" {
		testArgs = append(testArgs, "--testpat", config.TestPat)
	}
	if config.Mode != "" {
		testArgs = append(testArgs, "--mode", config.Mode)
	}

	if err := runStep("Run Test", "python2", testArgs, env); err != nil {
		log.Fatalf("Run test failed: %v", err)
	}

	if !config.Quiet {
		fmt.Println("MySQLtest Runner finished successfully.")
	}
}

func parseFlags() Config {
	quiet := flag.Bool("quiet", true, "Quiet mode")
	testSet := flag.String("testset", "", "Comma separated list of test cases")
	testPat := flag.String("testpat", "", "Test pattern")
	record := flag.Bool("record", false, "Run in record mode")
	test := flag.Bool("test", false, "Run in test mode")
	disableReboot := flag.Bool("disable-reboot", false, "Disable cluster reboot")
	configFile := flag.String("config", "config.json", "Path to configuration file")

	flag.Parse()

	// Handle record/test mutual exclusion/default
	mode := "test" // Default to test
	if *record {
		mode = "record"
	} else if *test {
		mode = "test"
	}

	return Config{
		Quiet:         *quiet,
		TestSet:       *testSet,
		TestPat:       *testPat,
		Mode:          mode,
		DisableReboot: *disableReboot,
		ConfigFile:    *configFile,
	}
}

func loadAppConfig(path string) (*AppConfig, error) {
	// If path is relative, make it relative to the executable or current working directory
	// For simplicity, we assume it's relative to CWD as the runner is executed from root usually
	
	bytes, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var config AppConfig
	if err := json.Unmarshal(bytes, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

func runStep(name string, cmdName string, args []string, env []string) error {
	fmt.Printf("[%s] Running: %s %s\n", name, cmdName, strings.Join(args, " "))
	cmd := exec.Command(cmdName, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = env
	return cmd.Run()
}
