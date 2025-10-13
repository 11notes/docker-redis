package main

import (
	"fmt"
	"strings"
	"syscall"
	"os"
	"os/exec"
	"regexp"

	"github.com/11notes/go"
)

const REDIS_CONFIG string = "/redis/etc/redis.conf"
const REDIS_UNSET_PASSWORD string = "-11"

var (
	Eleven eleven.New = eleven.New{}
	reRemoveLastLineBreak = regexp.MustCompile(`[^\S\n\r]*\n$`)
	reReplicaOf = regexp.MustCompile(`^# replicaof.*`)
)

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
	replaceEnv(REDIS_CONFIG)
	if err := syscall.Exec("/usr/local/bin/redis-server", []string{"redis-server", REDIS_CONFIG}, os.Environ()); err != nil {
		os.Exit(1)
	}
}

func cmd(){
	password := Eleven.Util.Getenv("REDIS_PASSWORD", REDIS_UNSET_PASSWORD)
	if(password == REDIS_UNSET_PASSWORD){
		password = Eleven.Util.GetenvFile(Eleven.Util.Getenv("REDIS_PASSWORD_FILE", "/run/secrets/redis_password"), REDIS_UNSET_PASSWORD)
		if(password == REDIS_UNSET_PASSWORD){
			Eleven.LogFatal("ERR", "no Redis password provided via REDIS_PASSWORD or REDIS_PASSWORD_FILE")
		}
	}
	args := os.Args[2:]
	for _, arg := range args {
		params := []string{"-h", os.Getenv("REDIS_HOST"), "--raw"}
		for _, a := range (strings.Split(arg, " ")) {
			params = append(params, a);
		}
		cmd := exec.Command("/usr/local/bin/redis-cli", params..., )
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid:true}
		cmd.Env = append(os.Environ(), "REDISCLI_AUTH=" + password)
		out, err := cmd.Output()
		if err != nil {
			Eleven.Log("ERR", "redis-cli: %s", err)
		}else{
			Eleven.Log("INF", arg)
			Eleven.Log("INF", reRemoveLastLineBreak.ReplaceAllString(string(out), ""))
		}
	}
}

func replica(){
	args := os.Args[2:]

	config, err := Eleven.Util.ReadFile(REDIS_CONFIG)
	if err != nil {
		Eleven.LogFatal("ERR", "Eleven.Util.ReadFile(%s): %s", REDIS_CONFIG, err)
	}

	if match, _ := regexp.MatchString("replicaof", config); !match {
		config += "\n" + fmt.Sprintf("replicaof %s 6379", args[0])
		err = Eleven.Util.WriteFile(REDIS_CONFIG, config)
		if err != nil {
			Eleven.LogFatal("ERR", "Eleven.Util.WriteFile(%s): %s", REDIS_CONFIG, err)
		}
		Eleven.Log("INF", "adding replicaof to config")
	}

	Eleven.Log("INF", "starting redis replica of master [%s]", args[0])
	server()
}

func memory(){
	config, err := Eleven.Util.ReadFile(REDIS_CONFIG)
	if err != nil {
		Eleven.LogFatal("ERR", "Eleven.Util.ReadFile(%s): %s", REDIS_CONFIG, err)
	}

	if match, _ := regexp.MatchString(`save ""`, config); !match {
		config = regexp.MustCompile(`save 3600.*`).ReplaceAllString(config, `save ""`)
		config = regexp.MustCompile(`appendonly yes`).ReplaceAllString(config, "appendonly no")
		config = regexp.MustCompile(`shutdown-on-sigint save`).ReplaceAllString(config, "shutdown-on-sigint nosave")
		config = regexp.MustCompile(`shutdown-on-sigterm save`).ReplaceAllString(config, "shutdown-on-sigterm nosave")
		err = Eleven.Util.WriteFile(REDIS_CONFIG, config)
		if err != nil {
			Eleven.LogFatal("ERR", "Eleven.Util.WriteFile(%s): %s", REDIS_CONFIG, err)
		}
	}	

	Eleven.Log("WRN", "database only run from memory, all data will be lost if container is terminated or restarted!")
	server()
}

func replaceEnv(path string){
	config, err := Eleven.Util.ReadFile(path)
	if err != nil {
		Eleven.LogFatal("ERR", "Eleven.Util.ReadFile(%s): %s", path, err)
	}

	password := Eleven.Util.Getenv("REDIS_PASSWORD", REDIS_UNSET_PASSWORD)
	if(password == REDIS_UNSET_PASSWORD){
		password = Eleven.Util.GetenvFile(Eleven.Util.Getenv("REDIS_PASSWORD_FILE", "/run/secrets/redis_password"), REDIS_UNSET_PASSWORD)
		if(password == REDIS_UNSET_PASSWORD){
			Eleven.LogFatal("ERR", "no Redis password provided via REDIS_PASSWORD or REDIS_PASSWORD_FILE")
		}
	}

	env := append(os.Environ(), "REDIS_PASSWORD=" + password)

	for _, e := range env {
		key := strings.Split(e, "=")[0]
		value := strings.Join(strings.Split(e, "=")[1:], "")
		if len(key) > 0 {
			if match, _ := regexp.MatchString(fmt.Sprintf(`\$%s`, key), config); match {
				Eleven.Log("DBG", "found global variable $%s in %s, replacing ...", key, path)
				config = regexp.MustCompile(fmt.Sprintf(`\$%s`, key)).ReplaceAllString(config, value)
			}
		}
	}

	err = Eleven.Util.WriteFile(path, config)
	if err != nil {
		Eleven.LogFatal("ERR", "Eleven.Util.WriteFile(%s): %s", path, err)
	}
}