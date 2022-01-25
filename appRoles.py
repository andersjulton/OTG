
"""
Script for deleting app role assignments.
Details in script cells below.
"""
#%%
import csv, requests
from tqdm import tqdm
#%% Helper functions
def Set_ClientSecretAccessToken(tenant_id: str, client_id: str, client_secret: str) -> dict:

        token_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/token'
        token_data = {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
            "resource": "https://graph.microsoft.com",
            "scope":"https://graph.microsoft.com"

        }
        token_request = requests.post(token_url, data=token_data)
        token = token_request.json()['access_token']

        return { 'Authorization' : f'Bearer {token}' , 'Content-Type' : 'application/json'}

def divide_chunks(big_list: list, n: int):
    """
    Function for dividing list into lists of equal size n
    """ 
    for i in range(0, len(big_list), n): 
        yield big_list[i:i + n]

#%% Use application with graph permissions to connect to Graph API
tenant_id = "d027b1fe-9231-4605-b90e-e930bc359715"
client_id = "9b4d82b5-fcab-4b60-8789-65d504aa4a29"
client_secret = "7fu7Q~R-cIgLVvlOWmFPcNLGEsrNDAJyzZTJt"

headers = Set_ClientSecretAccessToken(tenant_id, client_id, client_secret)

sess = requests.Session()
sess.headers.update(headers)
#%% Get application app roles
graph_url = "https://graph.microsoft.com/v1.0"

app_id = "a32aa0c3-1aee-4bbb-baf1-26e46fdae2e9"

app = (sess.get(f"{graph_url}/applications/{app_id}")).json()

app_name = app['displayName']
app_roles = app['appRoles']
app_role_ids = [app_role['id'] for app_role in app_roles]

# %% Get all current app role assignments for service principal
sp_id = "cc50291c-d3f9-4575-8935-29483d7f3919"

sp_assignments = (sess.get(f"{graph_url}/servicePrincipals/{sp_id}/appRoleAssignedTo")).json()
assignment_list = []
for assignments in sp_assignments['value']:
    assignment_list.append(assignments)

while True:
    try:
        sp_assignments = (sess.get(sp_assignments['@odata.nextLink'])).json()
        for assignments in sp_assignments['value']:
            assignment_list.append(assignments)
    except:
        break

# %% Delete assignments without app role
failed_deletes = []
with open(f'{app_name}-deletedAssignments_empty.csv', 'w') as delete_log:
    csw_writer = csv.writer(delete_log, delimiter=',')
    key_list = [key for key, value in assignment_list[0].items()]
    csw_writer.writerow(key_list)
    for assignment in tqdm(assignment_list):
        if assignment['app_role_id'] not in app_role_ids:
            delete_assignment = sess.delete(f"{graph_url}/servicePrincipals/{sp_id}/appRoleAssignedTo/{assignment['id']}")
            if delete_assignment.status_code != 204:
                failed_deletes.append(assignment)
                continue
            value_list = [value for key, value in assignment.items()]
            csw_writer.writerow(value_list)

# %% Extract app roles for next step
valid_app_roles = []
for role in app_roles:
    match role['displayName'].split(" - "):
        case ['HUB', vault, perm]:
            valid_app_roles.append(role)

valid_app_role_ids = [role['id'] for role in valid_app_roles]
# %% Delete directly assigned roles given by valid_app_roles
failed_dels_direct = []
with open(f'{app_name}-deletedAssignments_directlyAssigned_HUB.csv', 'w') as delete_log:
    csw_writer = csv.writer(delete_log, delimiter=',')
    key_list = [key for key, value in assignment_list[0].items()]
    csw_writer.writerow(key_list)
    for assignment in tqdm(assignment_list):
        if assignment['principalType'] == "Group":
            continue
        if assignment['appRoleId'] in valid_app_role_ids:
            delete_assignment = sess.delete(f"{graph_url}/servicePrincipals/{sp_id}/appRoleAssignedTo/{assignment['id']}")
            if delete_assignment.status_code != 204:
                failed_dels_direct.append(assignment)
                continue
            value_list = [value for key, value in assignment.items()]
            csw_writer.writerow(value_list)
# %% Delete assignments for specific app role and principal type

principal_type = "" # "User" or "Group"
app_role_id = ""

for assignment in assignment_list:
    if assignment['principalType'] == "Group":
        if assignment['appRoleId'] == app_role_id:
            match assignment['principalDisplayName'].split("."):
                case ["Approvals", senter, perm]: # THIS NEEDS TO BE MODIFIED ON A CASE-BY-CASE BASIS
                    delete_assignment = sess.delete(f"{graph_url}/servicePrincipals/{sp_id}/appRoleAssignedTo/{assignment['id']}")
                    if delete_assignment.status_code != 204:
                        print(f"Failed on {assignment['principalDisplayName']}")
                    
# %% Delete directly assigned "HUB - Alle" app role
for assignment in tqdm(assignment_list):
    if assignment['principalType'] == "User":
        if assignment['appRoleId'] == "58272759-4fc8-455d-a6e7-840d30aa88e9":
            delete_assignment = sess.delete(f"{graph_url}/servicePrincipals/{sp_id}/appRoleAssignedTo/{assignment['id']}")
            if delete_assignment.status_code != 204:
                print(f"Failed on {assignment['principalDisplayName']}")
# %% 

