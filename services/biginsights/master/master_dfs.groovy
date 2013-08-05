import org.cloudifysource.utilitydomain.context.ServiceContextFactory

context = ServiceContextFactory.getServiceContext()
config = new ConfigSlurper().parse(new File("master-service.properties").toURL())

def argsLine = "dfs " + args.join(' ')

println "About to execute " + context.serviceDirectory + "/hadoop.sh "
println "biginsights dir = " + config.BI_DIRECTORY_PREFIX + config.BigInsightInstall

new AntBuilder().sequential {	
    chmod(file:"${context.serviceDirectory}/hadoop.sh", perm:"ugo+rx")
	exec(executable:context.serviceDirectory + "/hadoop.sh", osfamily:"unix", failonerror:"false", spawn:"false") {
		arg("value":argsLine)
		env("key":"BIGINSIGHTS_HOME", "value":config.BI_DIRECTORY_PREFIX + config.BigInsightInstall)
	}
}
