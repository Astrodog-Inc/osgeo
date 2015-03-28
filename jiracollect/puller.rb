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

#### Configuration Parameters ####
sslenforce = 0 # Check SSL Certificates?
testsrc = 1 # Check to see if the source is actually JIRA
testdst = 1
debug = 1 # Enable Debugging
minticket = 1
maxticket = 2058
fullcollect = 0 # Delete Destination Directory Before Collecting?
srcjira = 'https://jira.codehaus.org/'
srcprefix = 'UDIG'
destdir = '/hv02.work/Clients/OSGeo/geoserver_jira' # Local Directory for JIRA Data
maxretries = 3
haltonfail = 0 # Halt on any failed ticket / HTTP transaction?
badtickets = Array.new()   # List of bad ticket IDs.
  badtickets.push(3222)

# Initialize Local Destination Directory and change to it.

if Dir.exists?(destdir)
  if debug > 0
    puts destdir + " Exists, Checking Permissions. Continuing."
    if !File.writable?(destdir)
      puts "Cannot write to " + destdir + ". Exiting."
      return -1
    end
  end
  if fullcollect == 1
    if debug > 0 
      puts "Full collection enabled. Recreating " + destdir + ". Continuing."
    end
    FileUtils.rm_rf(destdir)
    FileUtils.mkdir(destdir)
  end
else
  if debug > 0
    puts "Creating " + destdir + ". Continuing."
  end
  FileUtils.mkdir(destdir)
end
Dir.chdir(destdir)

srcagent = Mechanize.new()
dstagent = Mechanize.new()
if sslenforce == 0
  if debug > 0
    puts "SSL Enforcement Disabled. Continuing."
  end
  srcagent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  dstagent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

# Connect to JIRA. Make sure it's actually JIRA and has our project.

if testsrc == 1
  if debug > 0
    puts "Testing " + srcjira + " to see if it's JIRA. Continuing."
  end
  page =  srcagent.get(srcjira).body
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

  # If we've made it this far, it's JIRA. Make sure the srcprefix is valid
  begin
    srcagent.get(srcjira + 'browse/' + srcprefix)
  rescue
    if debug > 0
      puts srcprefix + " doesn't lead to a JIRA project. Exiting."
    end
    abort
  end
  if debug > 0
    puts "srcprefix is valid. Continuting."
  end
end

# We've got the source project, and we're ready to collect.
ticketid = 0
i = minticket
j = 1
while i <= maxticket
    ticketid = srcprefix + '-' + i.to_s
    jiraticket = ticketid + '/' + ticketid + '.xml'
    fetchurl = srcjira + 'si/jira.issueviews:issue-xml/' + jiraticket
    if !Dir.exists?(destdir)
      begin
        Dir.mkdir(ticketid)
      rescue
        if debug > 0; puts "Couldn't create " + ticketid + ". Exiting." end
        abort
      end
    end
    begin
      puts 'Fetching ' + fetchurl + ' . Continuting'
      ticketxml = srcagent.get(fetchurl)
      ticketxml.save_as(jiraticket)
   
    rescue
      if debug > 0; puts 'Collecting ticket at ' + fetchurl + ' failed. Continuing.' end
      if j <= maxretries
        if debug > 0; puts 'Retry ' + j.to_s + ' of ' + maxretries.to_s + '. Continuing.' end
        j = j + 1
        next
      else
        if haltonfail == 1
          if debug > 0; puts 'Exceeded ' + j.to_s + ' retries with haltonfail enabled. Exiting.' end
          abort
        end
        if debug > 0; puts 'Exceeded ' + maxretries.to_s + ' retries. Skipping.' end         
        j = 1
        i = i + 1
        next
      end
    end
    ticketparse = Nokogiri::XML(File.open(jiraticket))
    ticketparse.xpath("//attachment").each do |node|
      begin
        attachfile = node.attributes['name']
        attachid = node.attributes['id']
        attachment = attachid.to_s + '/' + attachfile.to_s
        attachurl = srcjira + 'secure/attachment/' + attachment
        srcagent.get(attachurl).save_as(ticketid + '/' + attachfile)
      rescue
        next
      end
    end
#    srcagent.get(srcjira + 'secure/attachment/' + 67467 + '/' + green.png)
    i = i + 1
end


