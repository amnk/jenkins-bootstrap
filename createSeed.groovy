import hudson.model.*
import hudson.plugins.git.*
import java.util.Collections
import java.util.List
import javaposse.jobdsl.plugin.*
import jenkins.model.*

println "Creating seed job"

def jobName = 'seed'
def project = new FreeStyleProject(Jenkins.instance, jobName)

List<BranchSpec> branches = Collections.singletonList(new BranchSpec('*/master'))
List<UserRemoteConfig> repos = Collections.singletonList(
        new UserRemoteConfig('https://github.com/amnk/jenkins-bootstrap.git', '', '', 'jenkins'))
GitSCM scm = new GitSCM(repos, branches, false, null, null, null, null);
project.setScm(scm)

def script = new ExecuteDslScripts.ScriptLocation(
    value = 'false', targets = 'jobX/seed.groovy', scriptText = '')
def jobDslBuildStep = new ExecuteDslScripts(
    scriptLocation = script,
    ignoreExisting = false,
    removedJobAction = RemovedJobAction.DELETE,
    removedViewAction = RemovedViewAction.DELETE,
    lookupStrategy = LookupStrategy.JENKINS_ROOT,
    additionalClasspath = '')

project.getBuildersList().add(jobDslBuildStep)
project.save()
Jenkins.instance.reload()

def job = Jenkins.instance.getItemByFullName(jobName)
def cause = new hudson.model.Cause.RemoteCause("localhost", "seed")
def causeAction = new hudson.model.CauseAction(cause)
Jenkins.instance.queue.schedule(job, 0, causeAction)
