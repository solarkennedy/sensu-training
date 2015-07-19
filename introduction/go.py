#!/usr/bin/env python
import argparse
import logging
import yaml

try:
    import http.client as http_client
except ImportError:
    # Python 2
    import httplib as http_client

import requests


def parse_args():
    parser = argparse.ArgumentParser(description='Update Udemy Course Data')
    parser.add_argument('section', help='Which Udemy section to update')
    parser.add_argument('--verbose', dest='verbose', action='store_true')
    return parser.parse_args()


def setup_verbose_logging():
    http_client.HTTPConnection.debuglevel = 1
    # You must initialize logging, otherwise you'll not see debug output.
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True


def load_secrets():
    secrets = load_yaml('secrets.yml')
    return secrets


def load_yaml(filename):
    with open(filename) as stream:
        return yaml.load(stream)


def setup_basics(secrets):
    """
    """
    basics = load_yaml('basics.yml')
    basics_endpoint = "https://www.udemy.com/course-manage/edit-basics/?courseId=%d" % secrets['courseid']

    headers = {'referer': basics_endpoint}
    basics['csrfmiddlewaretoken'] = secrets['cookies']['csrfmiddlewaretoken']
    r = requests.post(basics_endpoint, data=basics, headers=headers, cookies=secrets['cookies'])
    print r
    r.raise_for_status()


if __name__ == '__main__':
    args = parse_args()
    if args.verbose:
        setup_verbose_logging()
    secrets = load_secrets()
    if args.section == 'basics':
        setup_basics(secrets)
