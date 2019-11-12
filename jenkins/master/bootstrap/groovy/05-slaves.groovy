import hudson.model.*
import jenkins.model.*
import hudson.slaves.*

/**
 * INSERT "Launch Method" SNIPPET HERE
 */

// Define a "Permanent Agent"
Slave agent = new DumbSlave(
        "jenkins-slave-1",
        "/var/jenkins",
        new JNLPLauncher(true))
agent.nodeDescription = "Jenkins container slave to execute jobs"
agent.numExecutors = 5
agent.labelString = "jenkins-slave"
agent.mode = Node.Mode.EXCLUSIVE
agent.retentionStrategy = new RetentionStrategy.Always()

// Create a "Permanent Agent"
Jenkins.instance.addNode(agent)
