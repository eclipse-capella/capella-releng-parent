import org.zeroturnaround.zip.ZipUtil

// Workaround for https://bugs.eclipse.org/bugs/show_bug.cgi?id=453708
// Add copies of all referenced <repository> elements with type=1
// See https://www.eclipse.org/lists/epsilon-dev/msg00522.html for context



File contentXml = new File(project.build.directory + "/repository/content.xml")
def patchedContentXml = new File(project.build.directory + "/repository/content.xml")

def document = new XmlParser().parse(contentXml)
def references = document.references[0]

for (repository in references.repository) {
	def type1Repository = references.appendNode("repository");
	type1Repository.@uri = repository.@uri
	type1Repository.@url = repository.@url
	type1Repository.@options = "1"
	type1Repository.@type = "1"
}

references.@size = (references.@size as Integer) * 2

new XmlNodePrinter(new PrintWriter(new FileWriter(patchedContentXml))).print(document)

// Zip the update site (see pom.xml for context)
def destfile = project.build.directory + "/" + properties['packagedSiteName'] + "-site-" + properties['unqualifiedVersion'] + '.' + properties['buildQualifier'] + ".zip" 
ZipUtil.pack(new File(project.build.directory + "/repository"), new File(destfile));