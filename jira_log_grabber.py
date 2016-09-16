import subprocess, socket, string, re, sys, os, json

def find_between( s, first, last ):
     try:
          start = s.index( first ) + len( first )
          end = s.index( last, start )
          return s[start:end]
     except ValueError:
          return ""


def jira_get_logs( jiraserver, token ):

    global jira_token
    counter = 0

    print(jira_token)
    try:
        
        totalstring = ''' curl -H Content-Type:application/json -XGET -b ./cookie -k https://%s/rest/api/2/auditing/record?filter=total''' % ( jiraserver  )
        totalargs = totalstring.split()
        totalcomm = subprocess.Popen(totalargs, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = totalcomm.communicate()
        print stdout
 
        totalcount = int(find_between(stdout, "\"total\":", "," ))

        print type(totalcount)
        print totalcount

        remainder = totalcount%1000
        print remainder
    
        while (totalcount>0):

            logfile = open("./logfile.txt", "a")

            loggrabstring = ''' curl -H Content-Type:application/json -XGET -b ./cookie -k https://%s/rest/api/2/auditing/record?offset=%s''' % ( jiraserver, str(counter)  )
            loggrabargs = loggrabstring.split()
            loggrabcomm = subprocess.Popen(loggrabargs, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = loggrabcomm.communicate()

            json_output=json.dumps(json.loads(stdout), sort_keys=True, indent=4)
            logfile.write(json_output)
            counter+=1000
            totalcount-=1000
            #print "REMAINDER: " + str(remainder)
            #print "COUNTER: " + str(counter)
            #print "TOTALCOUNT: " + str(totalcount)
             

        logfile.close()

    except:
        print("Something went wrong!")



def jira_create_token( jiraserver, user, password ):

    global jira_token

    try:
        tokencreatestring = '''curl -H Content-Type:application/json -XPOST -c ./cookie -k https://%s/rest/auth/1/session -d {"username":"%s","password":"%s"}''' % ( jiraserver, user, password )
        tokencreateargs = tokencreatestring.split()
        tokencreatecomm = subprocess.Popen(tokencreateargs, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = tokencreatecomm.communicate()

        jira_token = find_between(stdout, "\"value\":\"", "\"}" )


    except:
        print "Problem generating token."

jiraserver=""
user=""
password=""

jira_create_token( jiraserver, user, password )

jira_get_logs( jiraserver, jira_token )
