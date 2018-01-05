from __future__ import print_function
import httplib2
import os
import itertools
import json

from apiclient import discovery
import oauth2client
from oauth2client import client
from oauth2client import tools
from oauth2client.service_account import ServiceAccountCredentials

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/sheets.googleapis.com-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/spreadsheets.readonly'
APPLICATION_NAME = 'Google Sheets API Python Quickstart'

def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'service_test.json')

    store = oauth2client.file.Storage(credential_path)
    credentials = ServiceAccountCredentials.from_json_keyfile_name('/root/.credentials/service.json', scopes=SCOPES)
    print(credentials)
    return credentials

def main():
    varlist = []
    credentials = get_credentials()
   
    http_auth = credentials.authorize(httplib2.Http())
    discoveryUrl = ('https://sheets.googleapis.com/$discovery/rest?'
                    'version=v4')
    service = discovery.build('sheets', 'v4', http=http_auth,
                              discoveryServiceUrl=discoveryUrl)

    spreadsheetId = ''

    #Generate list of names
    nameRange = 'Server List!A5:A111'
    result = service.spreadsheets().values().get(
        spreadsheetId=spreadsheetId, range=nameRange).execute()
    nameList = result.get('values', [])

    # Generate list of IP addresses
    addressRange = 'Server List!I5:I111'
    result2 = service.spreadsheets().values().get(
        spreadsheetId=spreadsheetId, range=addressRange).execute()
    addressList = result2.get('values', [])

    if not addressList:
        print('No data found.')
    else:
        print('System info:')
        #print(type(addressList))
        #print(type(nameList))
        for a in range(len(addressList)):
            if addressList[a]:
                print(nameList[a])
            else:
                nameList[a]=''
                addressList[a]=''

        #print(str(nameList))
        #print(str(varlist))



        # Tidy up lists
        merged_address_list = list(itertools.chain(*addressList))
        merged_name_list = list(itertools.chain(*nameList))
        # Debug - output final lists
        #print(json.dumps(merged_address_list))
        #print(json.dumps(merged_name_list))
        # write lines to file
        f=open('master_hostslist_ansible.txt','w')
        f.write('[all_servers]'+'\n')
        for i in range(len(merged_name_list)):
            f.write(merged_name_list[i]+' ansible_host='+merged_address_list[i]+'\n')

        f.close()

if __name__ == '__main__':
    main()
