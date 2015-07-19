#!/usr/bin/env python
import argparse
import json
import logging
import yaml

try:
    import http.client as http_client
except ImportError:
    # Python 2
    import httplib as http_client

import markdown
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

    print "Posting basics:"
    print basics
    r = requests.post(basics_endpoint, data=basics, headers=headers, cookies=secrets['cookies'])
    print r
    r.raise_for_status()


def setup_details(secrets):
    """
    """
    details = load_yaml('details.yml')
    details_endpoint = "https://www.udemy.com/course-manage/edit-details/?courseId=%d" % secrets['courseid']
    headers = {'referer': details_endpoint}
    description_html = markdown.markdown(details['description'])

    print "Posting Details"
    description_dict = {
        'description': str(description_html),
        'submit': 'Save',
        'csrfmiddlewaretoken': secrets['cookies']['csrfmiddlewaretoken'],
    }
    print description_dict
    r = requests.post(details_endpoint, data=description_dict, headers=headers, cookies=secrets['cookies'])
    print r
    r.raise_for_status()


def setup_goals(secrets):
    """
    """
    input_data = load_yaml('goals.yml')
    endpoint = "https://www.udemy.com/course-manage/edit-goals-and-audience/?courseId=%d" % secrets['courseid']
    headers = {'referer': endpoint}
    print "Posting Data:"
    output_data = {
        'csrfmiddlewaretoken': secrets['cookies']['csrfmiddlewaretoken'],
        'what_you_will_learn': json.dumps({"items": input_data['what_you_will_learn']}),
        'who_should_attend': json.dumps({"items": input_data['who_should_attend']}),
        'requirements': json.dumps({"items": input_data['requirements']}),
        'instructional_level': input_data['instructional_level'],
        'submit': 'Save',
    }
    print output_data
    r = requests.post(endpoint, data=output_data, headers=headers, cookies=secrets['cookies'])
    print r
    r.raise_for_status()


def setup_chapter(title, description, secrets):
    endpoint = "https://www.udemy.com/api-1.1/chapters/"
    referer = "https://www.udemy.com/course-manage/edit-curriculum/?courseId=%d" % secrets['courseid']
    headers = {
        'referer': referer,
        'X-Requested-With': 'XMLHttpRequest',
        'X-Udemy-Bearer-Token': secrets['cookies']['access_token'],
        'X-Udemy-Client-Id': secrets['cookies']['client_id'],
        'X-Udemy-Snail-Case': 'true',
    }
    output_data = {
        'csrfmiddlewaretoken': secrets['cookies']['csrfmiddlewaretoken'],
        'title': title,
        'description': description,
        'disableMemcacheGets': 1,
        'courseId': secrets['courseid'],
    }
    r = requests.post(endpoint, data=output_data, headers=headers, cookies=secrets['cookies'])
    print r
    r.raise_for_status()


def setup_curriculum(secrets):
    """
    """
#    input_data = load_yaml('curriculum.yml')
    setup_chapter(title="Test chapter title", description="test chapter description", secrets=secrets)


if __name__ == '__main__':
    args = parse_args()
    if args.verbose:
        setup_verbose_logging()
    secrets = load_secrets()
    if args.section == 'basics':
        setup_basics(secrets)
    if args.section == 'details':
        setup_details(secrets)
    if args.section == 'goals':
        setup_goals(secrets)
    if args.section == 'curriculum':
        setup_curriculum(secrets)
