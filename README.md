# AM-treetool
A shell script tool to export/import/clone Forgerock Access Management and ForgeRock Identity Cloud PaaS trees and journeys.

## Description:
A shell script which will export an AM authentication tree from any realm (default: /) to standard output and re-import into any realm from standard input (optionally renaming the tree). The tool will include scripts. Requires curl, jq, and uuidgen to be installed and available.


## Usage: 
    % ./amtree.sh ( -e | -E | -i | -I | -l | -d | -P ) [-h url -u user -p passwd [-r realm -f file -t tree] -o version]

    Export/import/list/describe/prune authentication trees.

    Actions/tasks (must specify only one):
    -e         Export an authentication tree.
    -E         Export all the trees in a realm.
    -S         Export all the trees in a realm as separate files of the format
               FileprefixTreename.json.
    -s         Import all the trees in the current directory
    -i         Import an authentication tree.
    -I         Import all the trees in a realm.
    -d         If -h is supplied, describe the indicated tree in the realm,
               otherwise describe the tree export file indicated by -f
    -D         If -h is supplied, describe all the trees in the realm, otherwise
               describe all tree export files in the current directory
    -l         List all the trees in a realm.
    -P         Prune orphaned configuration artifacts left behind after deleting
               authentication trees. You will be prompted before any destructive
               operations are performed.

    Parameters:
    -h url     Access Management host URL, e.g.: https://login.example.com/openam
    -u user    Username to login with. Must be an admin user with appropriate
               rights to manages authentication trees.
    -p passwd  Password.
    -r realm   Realm. If not specified, the root realm '/' is assumed. Specify
               realm as '/parent/child'. If using 'amadmin' as the user, login
               will happen against the root realm but subsequent operations will
               be performed in the realm specified. For all other users, login
               and subsequent operations will occur against the realm specified.
    -f file    If supplied, export/list to and import from <file> instead of
               stdout and stdin. For -S, use as file prefix
    -t tree    Specify the name of an authentication tree. Mandatory in
               combination with the following actions: -i, -e, -d.
    -o version Override version. Notation: "X.Y.Z" e.g. "6.5.2"
               Override detected version with any version. This is helpful in
               order to check if trees in one environment would be compatible 
               running in another environment (e.g. in preparation of migrating
               from on-prem to ForgeRock Identity Cloud PaaS. Only impacts these
               actions: -d, -l.

    Run ./amtree.sh without any parameters to display this usage information.

## Examples:
1) Export a tree called "Login" from the root realm to a file:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -e -t Login -f login.json  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -e -t Login > login.json  
  
2) Import a tree into a sub-realm from a file and rename it to "LoginTree":  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -i -t LoginTree -f login.json -r /parent/child  
    % cat login.json | ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -i -t LoginTree -r /parent/child  
  
3) Export all the trees from the root realm to a file:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -E -f trees.json  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -E > trees.json  
  
4) Export all the trees from the root realm to separate files in the current directory. 
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -S  
  
5) Import all the trees from a file into a sub-realm:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -I -f trees.json -r /parent/child  
    % cat trees.json | ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -I -r /parent/child  
  
6) Import all the trees(*.json) from the currrent directory into a sub-realm:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -s -r /parent/child  
  
7) Clone a tree called "Login" to a tree called "ClonedLogin":  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -e -t Login | ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -i ClonedLogin  
  
8) Copy a tree called "Login" to a tree called "ClonedLogin" on another AM instance:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -e -t Login | ./amtree.sh -h https://another.domain.org/openam -u amadmin -p password -i ClonedLogin  
  
9) Copy all the trees from one realm on one AM instnace to another realm on another AM instance:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -E -r /internal | ./amtree.sh -h https://another.domain.org/openam -u amadmin -p password -I -r /external  
  
10) Pruning:  
    % ./amtree.sh -P -h https://openam.example.com/openam -u amadmin -p password  
    % ./amtree.sh -P -h https://openam.example.com/openam -r /parent/child -u amadmin -p password  
  
   Sample output during pruning:  
       
    Analyzing authentication nodes configuration artifacts...  
       
    Total:    74  
    Orphaned: 37  
     
    Do you want to prune (permanently delete) all the orphaned node instances? (N/y): y  
    Pruning.....................................  
    Done.
  
11) List all the trees from the root realm to a file or the console:  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -l -f trees.txt  
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -l
  
12) Describe one specific tree export file or all .json files in the current directory:
    If no file name is supplied, describe all json files in the current directory (from -S)
    % ./amtree.sh -d -f tree1.json  
    % ./amtree.sh -D
  
13) Describe one specific tree in AM or all trees in the realm:
    If no file name is supplied, describe all json files in the current directory (from -S)
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -d -t tree1
    % ./amtree.sh -h https://openam.example.com/openam -u amadmin -p password -D

## Limitations:
This tool can't export passwords (including API secrets, etc), so these need to be manually added back to an imported tree or alternatively, export the source tree to a file, edit the file to add the missing fields before importing. Any other dependencies than scripts needed for a tree must also exist prior to import, for example inner-trees and custom authentication JARs. Currently, scripts are NOT given a new UUID on import; an option to allow re-UUID-ing scripts might be added in the future.
