# for now: start a small server in DO 
#!/bin/bash


TOKEN='put your token here' 
BASE_URL='https://api.digitalocean.com/v2'


echo "Get User Information"
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"  "$BASE_URL/account" | jq

echo "list all Droplets"
curl -X GET "$BASE_URL/droplets" \
    -H "Authorization: Bearer $TOKEN" 


TIMESTAMP=`date '+%Y%m%d%H%M%S'`
DROPLET_NAME="droplet-$TIMESTAMP"


echo "\n"

echo "Creating new Droplet $DROPLET_NAME with these specifications..."
#feel free to change the specs for droplet

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"example.com","region":"nyc3","size":"512mb","image":"ubuntu-14-04-x64","ssh_keys":null,"backups":false,"ipv6":true,"user_data":null,"private_networking":null,"volumes": null,"tags":["web"]}' "$BASE_URL/droplets"
