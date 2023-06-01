#!/bin/bash
# Seamless utility for docker #

cd ~/.crawlghpr

source config.py  || { echo "[-] Unable to find config.py file, Please Check ReadMe.md" ; exit 1 ; }

RECEPIENT_EMAIL="${recipient_email}"

EP_NOW="$(date +%s)"
EP_DELTA="$((${EP_NOW}-$((${DAYS_TO_CHECK}*86400))))"

cleanup(){
  # Clean Up TMP files
  rm -rf ${TMP_DIR}/*
  mkdir -p ${TMP_DIR} || { echo "[-] Unable to create ${TMP_DIR}" ; exit 1 ; }
}

check_gh_token(){
GH_STATUS="$(curl -sILk -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${GITHUB_REPO}" | grep '^HTTP/2 '| awk '{print $2}')"
[[ "${GH_STATUS}" == "200" ]] || { echo "[-] Either GH Token is invalid or Repo ${GITHUB_REPO} not authorized" ; exit 1 ; }
echo "[+] GH Token is valid and authorized for ${GITHUB_REPO}."
}

collect_gh(){
  STATE="$1"
  PAGENUM=1
  if [ "${STATE}" == "merged" ]
  then
    API_URL="https://api.github.com/repos/${GITHUB_REPO}/pulls?page=${PAGENUM}&per_page=${GH_PER_PAGE}&state=all"
  else 
    API_URL="https://api.github.com/repos/${GITHUB_REPO}/pulls?page=${PAGENUM}&per_page=${GH_PER_PAGE}&state=${STATE}"
  fi
  while true
  do
    # Collect State PR from repo (page by page)
    echo -ne "\r[*] Processing: Page ${PAGENUM} @ ${GITHUB_REPO} for [${STATE}] requests"
    curl -sSLk \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}"\
      -H "X-GitHub-Api-Version: 2022-11-28" \
      ${API_URL} | jq -r '[.[] | .html_url, .number, .state, .locked, .user.login, .updated_at, .title] | @sh' | sed 's|https://github.com|\nhttps://github.com|g' > ${TMP_DIR}/${STATE}.tmp

    # sanitize the downloaded data
    sed -i "/^'/d"  ${TMP_DIR}/${STATE}.tmp

    if [ "${STATE}" == "merged" ]
    then
      while read -r line; do
        PR_ID="$(echo ${line}| awk '{print $2}')"
        MR_STAT="$(curl -sILk -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${GITHUB_REPO}/pulls/${PR_ID}/merge" | grep '^HTTP/2' |awk '{print $2}')"
        # echo "$PR_ID = $MR_STAT"
        DT_STAMP="$(echo ${line}| awk '{print $6}' | sed -e 's|-|/|g' -e 's|T| |g' -e 's|Z||g')"
        EP_STAMP=$(bash -c "date -d ${DT_STAMP} +%s")
        [[ "${EP_STAMP}" -ge "${EP_DELTA}" ]] && [[ "${MR_STAT}" == "204" ]] && echo "${line}" >> ${TMP_DIR}/${STATE}.dat
      done <  ${TMP_DIR}/${STATE}.tmp
    else 
    # collect only those PR which are X days older
      while read -r line; do
        DT_STAMP="$(echo ${line}| awk '{print $6}' | sed -e 's|-|/|g' -e 's|T| |g' -e 's|Z||g')"
        EP_STAMP=$(bash -c "date -d ${DT_STAMP} +%s")
        [[ "${EP_STAMP}" -ge "${EP_DELTA}" ]] &&  echo "${line}" >> ${TMP_DIR}/${STATE}.dat
      done <  ${TMP_DIR}/${STATE}.tmp
    fi

    [[ "$(wc -l  ${TMP_DIR}/${STATE}.tmp | awk '{print $1}')" -lt "${GH_PER_PAGE}" ]] && echo -ne "\r[+] All PR's collected for [${STATE}]\t\t\t\t\t\t\n" && break
    [[ "${GH_PAGES_LIMIT}" == "${PAGENUM}" ]] && echo -ne "\r[+] Collected ${PAGENUM} pages for [${STATE}] as restricted by limit\t\t\t\t\t\t\n" && break
    ((PAGENUM=$PAGENUM+1))
  done
  touch ${TMP_DIR}/${STATE}.dat
}


txt_to_html(){
  # Convert collected API data to HTML with href tags #
  STATE="$1"
  echo "<h2>${STATE} Pull Requests:</h2><table><thead><tr><th>PR No.</th><th>Author</th><th>Updated At</th><th>Title</th></tr></thead><tbody>" >> ${TMP_DIR}/sendmail.html
  while read -r line; do
    PR_URL="$(echo ${line}| awk '{print $1}' | sed "s|'||g")"
    PR_ID="$(echo ${line}| awk '{print $2}'| sed "s|'||g")"
    PR_LOCK="$(echo ${line}| awk '{print $4}'| sed "s|'||g")"
    PR_AUTHOR="$(echo ${line}| awk '{print $5}'| sed "s|'||g")"
    PR_TIME="$(echo ${line}| awk '{print $6}'| sed "s|'||g")"
    PR_TITLE="$(echo -ne $(echo ${line}| awk -F" " '{ for (i=7; i<=NF; i++) print $i }') | sed -e "s|^'||g" -e "s|' '||g" ) "
    echo "<tr><td data-label="PR No:"><a href="${PR_URL}" target="_blank">${PR_ID}</a></td>" >> ${TMP_DIR}/sendmail.html
    echo "<td data-label="Author:"><a href="https://github.com/${PR_AUTHOR}" target="_blank">${PR_AUTHOR}</a></td>" >> ${TMP_DIR}/sendmail.html
    echo "<td data-label="Updated At:">${PR_TIME}</td>" >> ${TMP_DIR}/sendmail.html
    echo "<td data-label="Title:"><a href="${PR_URL}" target="_blank">${PR_TITLE}</a></td></tr>" >> ${TMP_DIR}/sendmail.html
  done < ${TMP_DIR}/${STATE}.dat
  echo "</tbody></table>" >> ${TMP_DIR}/sendmail.html

}

write_mail()
{
  # Write all Mail Body into a single file #
  COUNT_OPEN="$(wc -l ${TMP_DIR}/open.dat | awk '{print $1}')"
  COUNT_CLOSED="$(wc -l ${TMP_DIR}/closed.dat | awk '{print $1}')"
  COUNT_MERGED="$(wc -l ${TMP_DIR}/merged.dat | awk '{print $1}')"
  COUNT_TOTAL="$((${COUNT_OPEN}+${COUNT_CLOSED}+${COUNT_MERGED}))"
  REPONAME="<a href="https://github.com/${GITHUB_REPO}" target="_blank">${GITHUB_REPO}</a>"
  cp mail_template.html ${TMP_DIR}/sendmail.html
  sed -i -e "s|COUNT_OPEN|${COUNT_OPEN}|g" -e "s|COUNT_CLOSED|${COUNT_CLOSED}|g" -e "s|COUNT_MERGED|${COUNT_MERGED}|g" -e "s|COUNT_TOTAL|${COUNT_TOTAL}|g" -e "s|REPONAME|${REPONAME}|g" -e "s|DAYS_TO_CHECK|${DAYS_TO_CHECK}|g" -e "s|GITHUB_REPO|${GITHUB_REPO}|g" ${TMP_DIR}/sendmail.html
  txt_to_html "open"
  txt_to_html "closed"
  txt_to_html "merged"
  echo	"</main></body></html>" >> ${TMP_DIR}/sendmail.html
}

send_mail(){
  # Send an html mail file #
  python3 -m venv venv
  . ./venv/bin/activate
  sleep 1
  python mail_sender.py "${GITHUB_REPO}" "${RECEPIENT_EMAIL}"
  deactivate
}


## Mains ##

check_gh_token
cleanup
collect_gh "open"
collect_gh "closed"
collect_gh "merged"
write_mail
send_mail
cleanup


## E O F ##
