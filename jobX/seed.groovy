job('hello-world') {
  description("Render Hello world")

  scm {
    github("amnk/jenkins-bootstrap")
  }

  triggers {
    cron("*/5 * * * *")
  }

  publishers {
    archiveArtifacts('jobX/index.html')
    downstream('build-docker')
  }
}

job('build-docker') {
  description("Build Docker with rendered static file")

  scm {
    github("amnk/jenkins-bootstrap")
  }

  steps {
    copyArtifacts('hello-world') {
      includePatterns('*.html')
      targetDirectory('.')
      flatten()
      optional()
      buildSelector {
        latestSuccessful(true)
      }
    }

    dockerBuildAndPublish {
      repositoryName("amnk/jenkins-bootstrap")
      tag('bootstrap')
      dockerfileDirectory('jobX')
    }
  }

  publishers {
    downstream('run-docker')
  }
}

job('run-docker') {
  description("Run service on Amazon ECS")

  steps {
    shell("")
  }
}

buildPipelineView('Pipeline') {
  title('hello-world pipeline')
  displayedBuilds(50)
  selectedJob('build-docker')
  alwaysAllowManualTrigger()
  showPipelineParametersInHeaders()
  showPipelineParameters()
  showPipelineDefinitionHeader()
  refreshFrequency(60)
}
