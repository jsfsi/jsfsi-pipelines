/*
Set various Jenkins options. See comments below.
*/

import jenkins.model.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def jenkins = Jenkins.getInstance()

// Set the number of Jenkins executors so master can run seed job
jenkins.setNumExecutors(0)

// Add label to master node, and make it exclusive,
// so it only runs the seed job and no other jobs.
jenkins.setLabelString("master")

jenkins.setMode(hudson.model.Node.Mode.EXCLUSIVE)

// Enable CSRF Protection
jenkins.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Enable agent to master security subsystem
jenkins.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

jenkins.save()
