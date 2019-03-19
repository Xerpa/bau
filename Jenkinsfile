pipeline {
  agent any

  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
    disableResume()
    timeout(activity: true, time: 30)
    ansiColor('gnome-terminal')
    quietPeriod(10)
  }

  environment {
    VAULT_ACCESS_KEY = credentials("VAULT_ACCESS_KEY")
    VAULT_SECRET_KEY = credentials("VAULT_SECRET_KEY")
  }

  stages {
    stage("tests") {
      when {
        not {
          branch "master"
        }
      }

      steps {
          library 'libjenkins'

          doca(container: "bau")
          vault_auth()
          fetch_cache(key: "bau")
          in_container(exec: "mix format --check-formatted")
          in_container(exec: "bootstrap", env_vars: "MIX_ENV=test")
          store_cache(key: "bau", directories: ["_build/test", "deps"])
          in_container(exec: "mix test")
      }
    }
  }
}
