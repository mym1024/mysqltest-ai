package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"log"
)

// Config holds the command line arguments
type Config struct {
	Quiet         bool
	TestSet       string
	TestPat       string
	Mode          string // "record" or "test"
	DisableReboot bool
}

func main() {
	config := parseFlags()

	if !config.Quiet {
		fmt.Println("Starting MySQLtest Runner...")
		fmt.Printf("Config: %+v\n", config)
	}

	// 1. Setup Environment (Shell)
	if err := runStep("Setup Environment", "sh", "scripts/setup_env.sh"); err != nil {
		log.Fatalf("Setup environment failed: %v", err)
	}

	// 2. Deploy Cluster (Python 2)
	// Only deploy/reboot if disable-reboot is false
	if !config.DisableReboot {
		if err := runStep("Deploy Cluster", "python2", "scripts/deploy_cluster.py"); err != nil {
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

	if err := runStep("Run Test", "python2", testArgs...); err != nil {
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

	flag.Parse()

	// Handle record/test mutual exclusion/default
	mode := "test" // Default to test
	if *record {
		mode = "record"
	} else if *test {
		mode = "test"
	}
    // If both are set, last one wins or logic above decides. 
    // The prompt says "record|test" to switch.

	return Config{
		Quiet:         *quiet,
		TestSet:       *testSet,
		TestPat:       *testPat,
		Mode:          mode,
		DisableReboot: *disableReboot,
	}
}

func runStep(name string, cmdName string, args ...string) error {
	fmt.Printf("[%s] Running: %s %s\n", name, cmdName, strings.Join(args, " "))
	cmd := exec.Command(cmdName, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
    // Ensure scripts are executable if needed, or rely on interpreter
	return cmd.Run()
}
