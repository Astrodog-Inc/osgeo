# Copyright (c) 2015, Astrodog MRU - harrison.grundy@astrodoggroup.com (Sponsored by OSGeo)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistribution of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PRODCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES, LOSS OF USE, DATA OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


require 'mechanize'
require 'nokogiri'
require 'fileutils'

Project = Struct.new(:name, :minticket, :maxticket, :projectid)
projects = Array.new()

#### Configuration Parameters ####
localdir = '/hv02.work/Clients/OSGeo/jiradata/'
projects.push(Project.new("GEOS", 1, 6955, 10000))
dstjira = 'https://osgeo-org.atlassian.net'
sslenforce = 0
testdst = 1
debug = 1

dstagent = Mechanize.new()

if sslenforce == 0
  if debug > 0
    puts "SSL Enforcement Disabled. Continuing."
  end
  dstagent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

if testdst == 1
  if debug > 0
    puts "Testing " + dstjira + " to see if it's JIRA. Continuing."
  end
  page =  dstagent.get(dstjira).body
  pagedoc = Nokogiri::HTML(page)
  begin
    appname =  pagedoc.xpath("//meta[@name='application-name']").attribute('content')
    if appname.to_s != 'JIRA'
      if debug > 0
        puts "This doesn't look like JIRA. Exiting."
      end
      abort
    end
  rescue
    if debug > 0
      puts "This doesn't look like JIRA. Exiting."
    end
    abort
  end
  if debug > 0
    puts "It *is* JIRA. Continuing."
  end
end

Dir.chdir(localdir)

# Log in to JIRA

page = dstagent.get(dstjira + '/login')
loginform = page.form_with(:id => 'form-crowd-login')
loginform.username = 'harrison.grundy'
loginform.password = 


projects.each do |project|
  i = project["minticket"]
  Dir.chdir(localdir + project["name"])
  while i <= project["maxticket"]
    page = dstagent.get(dstjira + '/secure/CreateIssue.jspa')
    firstform = page.form_with(:action => 'CreateIssue.jspa')
    firstform.project = project["projectid"]
    firstform.issuetype = 1
    page = firstform.submit
    secondform = page.form_with(:action => 'CreateIssueDetails.jspa')
    secondform.summary = project["projectid"]
    page = secondform.submit
    
    
  end
end