#!/bin/bash
#------------------------
# Authors: Aecio dos Santos Pires <http://aeciopires.com>
# Date: 21 mar 2023
#
# Objective: Export datasources and dashboards of Grafana.
# Tested with Grafana 6.6.x
# 
# References:
# https://gist.github.com/crisidev/bd52bdcc7f029be2f295
# https://gist.github.com/crisidev/bd52bdcc7f029be2f295?permalink_comment_id=4197302#gistcomment-4197302



#---------------------------
# Variables
#---------------------------
PROGPATHNAME=$0
GRAFANA_URL=$1
API_TOKEN=$2
DEBUG=${3:-false}
PROGFILENAME=$(basename "$PROGPATHNAME")
PROGDIRNAME=$(dirname "$PROGPATHNAME")
BACKUPDIR=backup_grafana_dashboards_$(date +%Y%m%d_%H%M)
BACKUPDIR_DATASOURCES="${PROGDIRNAME}/${BACKUPDIR}/datasources"
BACKUPDIR_DASHBOARDS="${PROGDIRNAME}/${BACKUPDIR}/dashboards"
#----------------------------




#---------------------------
# Main
#---------------------------

mkdir -p "$BACKUPDIR_DATASOURCES"
mkdir -p "$BACKUPDIR_DASHBOARDS"

# Exporting datasources...

if [ "$DEBUG" == true ]; then
  echo -E "
    [DEBUG] Command to get datasource list...
    curl -s -H \"Authorization: Bearer $API_TOKEN\" ${GRAFANA_URL}/datasources\"
  "
fi

datasources=$(curl -s -H "Authorization: Bearer $API_TOKEN" ${GRAFANA_URL}/datasources)

for uid in $(echo "$datasources" | jq -r '.[] | .id'); do
  uid="${uid/$'\r'/}" # remove the trailing '/r'

  if [ "$DEBUG" == true ]; then
    echo -E "
      [DEBUG] Command to export datasource...
      curl -s -H \"Authorization: Bearer $API_TOKEN\" -X GET \"${GRAFANA_URL}/datasources/${uid}\"
    "
  fi

  curl -s -H "Authorization: Bearer $API_TOKEN" -X GET "${GRAFANA_URL}/datasources/${uid}" | jq > "${BACKUPDIR_DATASOURCES}/grafana-datasource-${uid}.json"
  slug=$(cat "${BACKUPDIR_DATASOURCES}/grafana-datasource-${uid}.json" | jq -r '.name' | tr -s ' ' | tr ' ' '_')
  mv "${BACKUPDIR_DATASOURCES}/grafana-datasource-${uid}.json" "${BACKUPDIR_DATASOURCES}/grafana-datasource-${slug}-${uid}.json" # rename with datasource name and id
  echo "[INFO] Datasource ${slug}-${uid} exported"
  echo "[INFO] Encrypting the file ${BACKUPDIR_DATASOURCES}/grafana-datasource-${slug}-${uid}.json..."
done



# Exporting dashboards...

if [ "$DEBUG" == true ]; then
  echo -E "
    [DEBUG] Command to get dashboard list...
    curl -s -H \"Authorization: Bearer $API_TOKEN\" ${GRAFANA_URL}/search\"
  "
fi

dashboards=$(curl -s -H "Authorization: Bearer $API_TOKEN" ${GRAFANA_URL}/search)

for uid in $(echo "$dashboards" | jq -r '.[] | .uid'); do
  uid="${uid/$'\r'/}" # remove the trailing '/r'

  if [ "$DEBUG" == true ]; then
    echo -E "
      [DEBUG] Command to export dashboard...
      curl -s -H \"Authorization: Bearer $API_TOKEN\" -X GET \"${GRAFANA_URL}/dashboards/uid/${uid}\"
    "
  fi
  curl -s -H "Authorization: Bearer $API_TOKEN" -X GET "${GRAFANA_URL}/dashboards/uid/${uid}" | jq > "${BACKUPDIR_DASHBOARDS}/grafana-dashboard-${uid}.json"
  slug=$(cat "${BACKUPDIR_DASHBOARDS}/grafana-dashboard-${uid}.json" | jq -r '.meta.slug' | tr -s ' ' | tr ' ' '_')
  mv "${BACKUPDIR_DASHBOARDS}/grafana-dashboard-${uid}.json" "${BACKUPDIR_DASHBOARDS}/grafana-dashboard-${slug}-${uid}.json" # rename with dashboard name and id
  echo "[INFO] Dashboard ${slug}-${uid} exported"
done