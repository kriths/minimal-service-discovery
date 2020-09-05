#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.request

import boto3


# Read environment
ENV_URL_PATTERN = os.getenv('URL_PATTERN', 'http://{ip}')
ENV_EXPECTED_STATUS_CODES = os.getenv('EXPECTED_STATUS_CODES', '200')
ENV_GRACE_PERIOD = os.getenv('GRACE_PERIOD', '60')  # In seconds
ENV_CHECK_INTERVAL = os.getenv('CHECK_INTERVAL', '5')  # In seconds
ENV_DNS_TTL = os.getenv('DNS_TTL', '60')  # In seconds
HOSTED_ZONE = os.environ['HOSTED_ZONE']
DOMAIN = os.environ['DOMAIN']
SUBDOMAIN = os.environ['SUBDOMAIN']
ASG_ID = os.environ['ASG_ID']


# Parse environment
URL_PATTERN = ENV_URL_PATTERN
EXPECTED_STATUS_CODES = [int(s) for s in ENV_EXPECTED_STATUS_CODES.split(',')]
GRACE_PERIOD = int(ENV_GRACE_PERIOD)
CHECK_INTERVAL = int(ENV_CHECK_INTERVAL)
DNS_TTL = int(ENV_DNS_TTL)


asg_client = boto3.client('autoscaling')
ec2_client = boto3.client('ec2')
r53_client = boto3.client('route53')


def get_public_ip(instance_id):
    """Get public ip by EC2 instance id"""
    instances = ec2_client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances']
    if not instances or len(instances) == 0:
        print("No matching instance found (yet)...", file=sys.stderr)
        return None

    instance = instances[0]
    return instance['PublicIpAddress']


def check_instance_state(instance_id):
    """Check service state for a single instance"""
    print(f"Checking instance state for {instance_id}")
    public_ip = get_public_ip(instance_id)
    if not public_ip:
        return False, None

    url = URL_PATTERN.replace("{ip}", public_ip)
    print(f"Checking url: {url}")
    try:
        req = urllib.request.urlopen(url)
    except:
        # Whatever happened, connection was unsuccessful
        return False, None

    print(f"Got status code: {req.status}")
    return req.status in EXPECTED_STATUS_CODES, public_ip


def remove_current_records(record_name):
    """Remove all current records, if any exist"""
    records = r53_client.list_resource_record_sets(HostedZoneId=HOSTED_ZONE)['ResourceRecordSets']
    for record in records:
        if record['Name'] == record_name:
            r53_client.change_resource_record_sets(
                HostedZoneId=HOSTED_ZONE,
                ChangeBatch={
                    'Changes': [{
                        'Action': 'DELETE',
                        'ResourceRecordSet': record
                    }]
                }
            )


def check_and_set_dns():
    """Check all instances of the asg and add reachable IPs to DNS record"""
    group = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[ASG_ID])['AutoScalingGroups'][0]
    servers = group['Instances']
    reachable_ips = []
    for server in servers:
        instance_id = server['InstanceId']
        status = check_instance_state(instance_id)
        if status[0]:
            reachable_ips.append(status[1])

    record_name = f'{DOMAIN}.'
    if SUBDOMAIN:
        record_name = f'{SUBDOMAIN}.{record_name}'

    if len(reachable_ips) == 0:
        print("All hosts down!", file=sys.stderr)
        remove_current_records(record_name)
    else:
        r53_client.change_resource_record_sets(
            HostedZoneId=HOSTED_ZONE,
            ChangeBatch={
                'Changes': [{
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': record_name,
                        'TTL': DNS_TTL,
                        'Type': 'A',
                        'ResourceRecords': [{'Value': ip} for ip in reachable_ips],
                    }
                }]
            }
        )


def on_launch(events, context):
    event = events['Records'][0]['Sns']
    message = json.loads(event['Message'])
    instance_id = message['EC2InstanceId']
    start_time = int(time.time())
    while int(time.time()) <= start_time + GRACE_PERIOD:
        if check_instance_state(instance_id)[0]:
            print(f"Instance {instance_id} is OK")
            check_and_set_dns()
            return

        print(f"Health check failed for {instance_id}")
        time.sleep(CHECK_INTERVAL)
