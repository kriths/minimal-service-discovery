#!/usr/bin/env python3
import os
import sys

import boto3

asg_client = boto3.client('autoscaling')
ec2_client = boto3.client('ec2')

# Read ASG name from terraform
asg_name = os.popen('terraform output asg_id').read().strip()

asgs = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])['AutoScalingGroups']

if len(asgs) == 0:
    print('Cannot find matching ASG', file=sys.stderr)
    exit(1)

servers = asgs[0]['Instances']

for server in servers:
    instance_id = server['InstanceId']
    instance = ec2_client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
    print(instance['PublicIpAddress'])
