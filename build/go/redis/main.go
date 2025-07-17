package main

import (
	"fmt"
	"io/ioutil"
	"strings"
	"syscall"
	"io"
	"os"
	"os/exec"
	"regexp"
	"time"
)

const RedisConfig = "/redis/etc/redis.conf"

var (
	reRemoveLastLineBreak = regexp.MustCompile(`[^\S\n\r]*\n$`)
	reReplicaOf = regexp.MustCompile(`^# replicaof.*`)
)

func logInfo(s string){
	log(os.Stdout, fmt.Sprintf("INFO %s", s))
}

func logError(s string){
	log(os.Stderr, fmt.Sprintf("ERROR %s", s))
}

func logWarning(s string){
	log(os.Stderr, fmt.Sprintf("WARNING %s", s))
}

func log(r io.Writer, s string) {
	fmt.Fprintf(r, "%s %s\n", time.Now().Format(time.RFC3339), s)
}

func main() {
	if(len(os.Args) > 1){
		args := os.Args[1:]
		switch args[0] {
			case "--cmd":
				cmd()

			case "--replica":
				replica()

			case "--in-memory":
				memory()
		}
	}else{
		server()
	}
}

func server(){
	replaceEnv(RedisConfig)
	if err := syscall.Exec("/usr/local/bin/redis-server", []string{"redis-server", RedisConfig}, os.Environ()); err != nil {
		os.Exit(1)
	}
}

func cmd(){
	os.Setenv("REDISCLI_AUTH", os.Getenv("REDIS_PASSWORD"))
	args := os.Args[2:]
	for _, arg := range args {
		params := []string{"-h", os.Getenv("REDIS_HOST"), "--raw"}
		for _, a := range (strings.Split(arg, " ")) {
			params = append(params, a);
		}
		cmd := exec.Command("/usr/local/bin/redis-cli", params...)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid:true}
		cmd.Env = os.Environ()
		out, err := cmd.Output()
		if err != nil {
			logError(fmt.Sprintf("redis-cli: %s", err))
		}else{
			logInfo(arg)
			logInfo(reRemoveLastLineBreak.ReplaceAllString(string(out), ""))
		}
	}
}

func replica(){
	args := os.Args[2:]

	config, err := readFile(RedisConfig)
	if err != nil {
		logError(fmt.Sprintf("readFile(%s): %s", RedisConfig, err))
		os.Exit(1)
	}

	if match, _ := regexp.MatchString("replicaof", config); !match {
		config += "\n" + fmt.Sprintf("replicaof %s 6379", args[0])
		err = writeFile(RedisConfig, config)
		if err != nil {
			logError(fmt.Sprintf("writeFile(%s): %s", RedisConfig, err))
			os.Exit(1)
		}
		logInfo("adding replicaof to config")
	}	

	logInfo(fmt.Sprintf("starting redis replica of master [%s]", args[0]))
	server()
}

func memory(){
	config, err := readFile(RedisConfig)
	if err != nil {
		logError(fmt.Sprintf("readFile(%s): %s", RedisConfig, err))
		os.Exit(1)
	}

	if match, _ := regexp.MatchString(`save ""`, config); !match {
		config = regexp.MustCompile(`save 3600.*`).ReplaceAllString(config, `save ""`)
		config = regexp.MustCompile(`appendonly yes`).ReplaceAllString(config, "appendonly no")
		config = regexp.MustCompile(`shutdown-on-sigint save`).ReplaceAllString(config, "shutdown-on-sigint nosave")
		config = regexp.MustCompile(`shutdown-on-sigterm save`).ReplaceAllString(config, "shutdown-on-sigterm nosave")
		err = writeFile(RedisConfig, config)
		if err != nil {
			logError(fmt.Sprintf("writeFile(%s): %s", RedisConfig, err))
			os.Exit(1)
		}
	}	

	logWarning("database only run from memory, all data will be lost if container is terminated or restarted!")
	server()
}

func replaceEnv(path string){
	config, err := readFile(path)
	if err != nil {
		logError(fmt.Sprintf("readFile(%s): %s", path, err))
		os.Exit(1)
	}

	for _, e := range os.Environ() {
		key := strings.Split(e, "=")[0]
		value := os.Getenv(key)
		if len(key) > 0 {
			if match, _ := regexp.MatchString(fmt.Sprintf(`\$%s`, key), config); match {
				logInfo(fmt.Sprintf("found global variable $%s in %s, replacing ...", key, path))
				config = regexp.MustCompile(fmt.Sprintf(`\$%s`, key)).ReplaceAllString(config, value)
			}
		}
	}

	err = writeFile(path, config)
	if err != nil {
		logError(fmt.Sprintf("writeFile(%s): %s", path, err))
		os.Exit(1)
	}

	os.Setenv("REDISCLI_AUTH", os.Getenv("REDIS_PASSWORD"))
}

func readFile(path string) (string, error){
	content, err := ioutil.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

func writeFile(path string, content string) error{
	err := ioutil.WriteFile(path, []byte(content), os.ModePerm)	
	if err != nil {
		return err
	}
	return nil
}