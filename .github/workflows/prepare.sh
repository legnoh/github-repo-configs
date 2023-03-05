#!/bin/bash

set -x

GITHUB_API_URL=${GITHUB_API_URL:-"https://api.github.com"}
GITHUB_REPOSITORY_OWNER=${GITHUB_REPOSITORY_OWNER:?}
GITHUB_TOKEN=${GITHUB_TOKEN:?}

mkdir -p ./tmp

echo "Step1: Get GitHub Repositories"
curl -G "${GITHUB_API_URL}/users/${GITHUB_REPOSITORY_OWNER}/repos" \
  --data-urlencode "per_page=100" 2> /dev/null \
  | jq '{ repos: [sort_by(.name) | .[] | select(.archived == false and .visibility == "public")] }' > ./repos.auto.tfvars.json

cat ./repos.auto.tfvars.json | jq -r ".repos[].name" > ./tmp/repo_names_gh
if [[ $(cat ./tmp/repo_names_gh | wc -l) -eq 0 ]]; then
  echo "repo_names file is something wrong. exit."
  exit 1
fi

echo "Step2: Get repo info from terraform state"
terraform state list module.repos \
  | grep -v "::debug::stdout:" \
  | grep .github_repository.repo \
  | sed -e 's/^module.repos\[\"\(.*\)\"\].github_repository.repo/\1/' \
  | sort | uniq > ./tmp/repo_names_tf
diff ./tmp/repo_names_tf ./tmp/repo_names_gh > ./tmp/repos.diff

echo "Step3: Import and Destroy"
while read diffline
do
    annotate=${diffline::2}
    repo=${diffline:2}

    # Created --> import
    if [[ ${annotate} == '> ' ]]; then
      echo "import: ${repo}"
      terraform import module.repos\[\"${repo}\"\].github_repository.repo ${repo}

    # Archived/Deleted -> state rm
    elif [[ ${annotate} == '< ' ]]; then
      echo "state rm: ${repo}"
      terraform state rm module.repos\[\"${repo}\"\]
    fi

done < ./tmp/repos.diff
