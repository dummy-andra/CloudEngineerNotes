#!/usr/bin/env python3
import json
import urllib,  os, sys, logging, time
import configparser, getopt
from operator import itemgetter, attrgetter, methodcaller

import sys
import redminelib
from redminelib import Redmine
from redminelib.exceptions import ResourceAttrError, ResourceNotFoundError, JSONDecodeError, ValidationError
import time

class Discover(object):

    containers = {}
    hosts = {}

    def __init__(self, config):
        self.config = config

    def create_content(self, config, run_data=[]):
        try:
            opts, args = getopt.getopt(sys.argv[1:], "vn")
        except getopt.GetoptError as err:
            sys.exit(2)
        for o, a in opts:
            if o == "-v":
                logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)
            if o == "-n":
                dryrun = True
        if len(args) > 0:
            environments = args
        else:
            environments = config.get("general", "environments").split()
        pageTitle = config.get('wiki','containertitle')
        content = []
        content.append('h1. ' + pageTitle + '\n\n')
        #content.append('Automatically discovered on ' + time.strftime('%d %B %Y') + '. _Do not update this page manually._')
        content.append('Automatically runned on ' + time.strftime("%d %B %Y, %H:%M:%S") + '. _Do not update this page manually._')
        content.extend(run_data)

        for environment in environments:
            #print environment
            logging.debug("Environment: %s", environment)
            envLabel = config.get(environment, 'label')
            content.append('\nh2. Environment: {}\n'.format(envLabel))
            content.append('\n')
    #       disc.load_hosts(environment)
            self.load_containers(environment)
            self.buildgraph(content)
            content.append('\n')
        return "\n".join(content)

    def write_page(self,  config):
        server = self.config.get('wiki','server')
        apikey = self.config.get('wiki','apikey')
        projectName = self.config.get('wiki','project')
        pageName = self.config.get('wiki','containerpage')
        #pageTitle = self.config.get('wiki','title')
        server = Redmine(server, key=apikey, requests={'verify': True})
        project = server.project.get(projectName)

        try:
            wiki_page = server.wiki_page.get(pageName, project_id=project.id)
            run_data = []
            result = wiki_page.text.split('\n')
            for element in result:
                if (element.startswith('Automatically runned on ')):
                    run_data.append(element)
                    print(run_data)       
            content = self.create_content(config, run_data)
            server.wiki_page.update(pageName, project_id=project.id, text=content)

        except ResourceNotFoundError:
            content = self.create_content(config)
            wiki_page = server.wiki_page.create(project_id=project.id, title=pageName, text=content)
   
    def write_stdout(self, content):
        #pass
        print (content)


    def get_operation(self, environment, url):
        rancherUrl = self.config.get(environment, "rancher_url", vars={'env': environment})
        rancherAccessKey = self.config.get(environment, "rancher_access_key")
        rancherSecretKey = self.config.get(environment, "rancher_secret_key")
        realm = "Enter API access key and secret key as username and password"

        auth_handler = urllib.request.HTTPBasicAuthHandler()
        auth_handler.add_password(realm=realm, uri=rancherUrl, user=rancherAccessKey, passwd=rancherSecretKey)
        opener = urllib.request.build_opener(auth_handler)
        urllib.request.install_opener(opener)
        f = urllib.request.urlopen(url)
        rawdata = f.read()
        f.close()
        # import pdb; pdb.set_trace()
        result = json.loads(rawdata.decode("utf-8"))
        return result


    def load_containers(self, environment):
        self.containers = {}
        rancherUrl = config.get(environment, "rancher_url", vars={'env': environment})
        structdata = self.get_operation(environment, rancherUrl + "/containers?limit=1000")
        for instance in structdata['data']:
            imageUuid = instance['imageUuid']
            if imageUuid.startswith("docker:rancher/") and not imageUuid.startswith("docker:rancher/lb-service-haproxy"): continue
            imageUuid = imageUuid[7:]
            containerStruct = self.containers.setdefault(imageUuid, [])
            containerStruct.append(instance)
            #print instance

    def load_hosts(self, environment):
        self.hosts = {}
        rancherUrl = config.get(environment, "rancher_url", vars={'env': environment})
        structdata = self.get_operation(environment, rancherUrl + "/hosts")
        for instance in structdata['data']:
            name = instance['hostname']
            hostId = instance['id']
            self.hosts[hostId] = name
            self.containers[hostId] = []
        #print self.hosts

    def buildgraph(self, content):
        content.append('|_. Image |_. Container |_. State |_. MemLimit |')
        for imageName, containers in sorted(self.containers.items()):
            #content.append('h3. {}\n'.format(imageName))
            for container in sorted(containers, key=itemgetter('name')):
#               if container['imageUuid'].startswith("docker:rancher/"): continue
                memoryRes = container.get('memory', 0)
                if memoryRes is None: memoryRes = 0
                memoryRes = memoryRes / 1048576
                content.append('| {} | {} | {} |>. {} |'.format(imageName, container['name'], container['state'], memoryRes))
#           content.append('\n')

if __name__ == '__main__':
    config = configparser.SafeConfigParser()
    config.read('../env-wikibot/rancher.cfg')
    dryrun = False
    disc = Discover(config)
    if dryrun:
        disc.write_stdout(disc.create_content(config))
    else:
        disc.write_page(config)
    #print "Done"
