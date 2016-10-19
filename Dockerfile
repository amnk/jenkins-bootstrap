FROM jenkins:latest
RUN mkdir -p /var/jenkins_home/init.groovy.d
COPY createSeed.groovy /var/jenkins_home/init.groovy.d/createSeed.groovy
RUN /usr/local/bin/install-plugins.sh job-dsl scm-api branch-api git github github-api docker-build-publish build-pipeline-plugin copyartifact
