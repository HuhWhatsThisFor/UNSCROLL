#!/usr/bin/env python3
"""Read-only validation of downloaded Apple profiles. Does not register IDs or alter signing."""
import argparse
import datetime
import plistlib
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app-profile', required=True)
parser.add_argument('--monitor-profile', required=True)
parser.add_argument('--bundle-id', required=True)
parser.add_argument('--app-group', required=True)
args = parser.parse_args()
teams = []
errors = []
for label, path, bundle in [('App', args.app_profile, args.bundle_id), ('Monitor', args.monitor_profile, args.bundle_id + '.monitor')]:
    try:
        result = subprocess.run(['security', 'cms', '-D', '-i', path], capture_output=True, check=True)
        profile = plistlib.loads(result.stdout)
        entitlements = profile.get('Entitlements', {})
        team = profile.get('TeamIdentifier', [])
        teams.append(team)
        if entitlements.get('application-identifier') != (team[0] + '.' + bundle if team else ''):
            errors.append(f'{label}: profile must match the explicit bundle ID {bundle}.')
        if entitlements.get('com.apple.developer.family-controls') is not True:
            errors.append(f'{label}: Family Controls is missing.')
        if args.app_group not in entitlements.get('com.apple.security.application-groups', []):
            errors.append(f'{label}: configured App Group is missing.')
        expiration = profile.get('ExpirationDate')
        if not expiration or expiration.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
            errors.append(f'{label}: profile has expired or has no expiration date.')
        if not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices'):
            print(f'{label}: distribution profile; ensure this matches your intended signing method.')
        print(f'{label}: decoded profile for {bundle}.')
    except (subprocess.CalledProcessError, OSError, ValueError, plistlib.InvalidFileException) as error:
        errors.append(f'{label}: cannot decode profile ({type(error).__name__}).')
if len(teams) == 2 and teams[0] != teams[1]:
    errors.append('App and monitor belong to different teams.')
if errors:
    for error in errors:
        print('FAIL: ' + error, file=sys.stderr)
    sys.exit(1)
print('PASS: explicit IDs, common team, Family Controls, App Group, and expiration verified.')
print('Next: Xcode must successfully sign both targets; verify system shields on the provisioned iPhone.')
