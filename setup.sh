#!/bin/bash

set -e

function get_latest_runs() {
  local owner=$1
  local repo=$2
  local event=$3

  gh api "/repos/${owner}/${repo}/actions/runs?event=${event}" \
    | jq -r "[ .workflow_runs[] \
      | { name:.name, updated_at:.updated_at, head_sha:.head_sha, conclusion:.conclusion, jobs_url:.jobs_url }] as \$wf_runs \
      | \$wf_runs[0].head_sha as \$first_sha \
      | \$wf_runs[] | select(.head_sha == \$first_sha)"
}

rm -rf ./tmp && mkdir -p ./tmp

if [[ -n ${GITHUB_ACTION} ]]; then
  echo "Running on GitHub Actions"
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#default-environment-variables
  export GITHUB_OWNER=${GITHUB_REPOSITORY_OWNER:-}
else
  echo "Running on local"
  # https://cli.github.com/manual/gh_help_environment
  # https://search.opentofu.org/provider/opentofu/github/latest#argument-reference
  export GITHUB_OWNER=${GITHUB_OWNER:?}
fi
export TF_VAR_GITHUB_OWNER=${GITHUB_OWNER}

gh auth status
echo "------------------"

echo "Step1: Get GitHub Repositories"
gh repo list --limit 1000 --json=name,defaultBranchRef,languages,repositoryTopics,isEmpty,isArchived \
  | jq "[sort_by(.name) | .[] \
      | select(.isEmpty == false and .isArchived == false) \
      | .repositoryTopics |= if . != null then [.[].name] else [] end \
      | .languages |= if length > 0 then map(.node.name) else [] end \
      | { name:.name, default_branch:.defaultBranchRef.name, languages:.languages, topics:.repositoryTopics, pr_job_names:[] } \
    ] as \$res \
    | { repos: \$res }" > ./repos.auto.tfvars.json

cat ./repos.auto.tfvars.json | jq -r ".repos[].name" > ./tmp/repo_names_gh
if [[ $(cat ./tmp/repo_names_gh | wc -l) -eq 0 ]]; then
  echo "repo_names file is something wrong. exit."
  exit 1
fi

echo "Step2: Get repo info from tofu state"
tofu state list module.repos \
  | grep .github_repository.repo \
  | sed -e 's/^module.repos\[\"\(.*\)\"\].github_repository.repo/\1/' \
  | sort | uniq > ./tmp/repo_names_tf
set +e
diff ./tmp/repo_names_tf ./tmp/repo_names_gh > ./tmp/repos.diff
set -e

echo "Step3: Import and Destroy"
while read diffline
do
    annotate=${diffline::2}
    repo=${diffline:2}

    # Created --> import
    if [[ ${annotate} == '> ' ]]; then
      echo "-> import: ${repo}"

      echo "--> github_repository.repo"
      tofu import "module.repos[\"${repo}\"].github_repository.repo" ${repo}
      echo "--> github_branch_default.main"
      tofu import "module.repos[\"${repo}\"].github_branch_default.main" ${repo}

      default_branch=$(cat ./repos.auto.tfvars.json | jq -r ".repos[] | select(.name == \"${repo}\") | .default_branch")

      ## codeowners file
      if gh api --silent -X HEAD "/repos/${GITHUB_OWNER}/${repo}/contents/.github/CODEOWNERS" 2> /dev/null; then
        echo "--> github_repository_file.codeowners"
        tofu import \
          "module.repos[\"${repo}\"].github_repository_file.codeowners[0]" "${repo}/.github/CODEOWNERS:${default_branch}"
      fi

      ## automerge.yml file
      if gh api --silent -X HEAD "/repos/${GITHUB_OWNER}/${repo}/contents/.github/workflows/automerge.yml" 2> /dev/null; then
        echo "--> github_repository_file.codeowners"
        tofu import \
          "module.repos[\"${repo}\"].github_repository_file.automerge[0]" "${repo}/.github/workflows/automerge.yml:${default_branch}"
      fi

      ## uv-lock.yml file
      if gh api --silent -X HEAD "/repos/${GITHUB_OWNER}/${repo}/contents/.github/workflows/uv-lock.yml" 2> /dev/null; then
        echo "--> github_repository_file.uv_locker"
        tofu import \
          "module.repos[\"${repo}\"].github_repository_file.uv_locker[0]" "${repo}/.github/workflows/uv-lock.yml:${default_branch}"
      fi

      ## ruleset
      rule_id=$(gh api "/repos/${GITHUB_OWNER}/${repo}/rulesets" | jq ".[0].id")
      if [[ "${rule_id}" != "null" ]]; then
        echo "--> github_repository_ruleset.main"
        tofu import \
          "module.repos[\"${repo}\"].github_repository_ruleset.main[0]" "${repo}:${rule_id}"
      fi

      ## variables
      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/variables" --jq '.variables[] | select(.name == "G_BUMP_BOT_ID") | .name' 2> /dev/null | grep -q "G_BUMP_BOT_ID"; then
        echo "--> github_actions_variable.bump_bot_id"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_variable.bump_bot_id" "${repo}:G_BUMP_BOT_ID"
      fi

      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/variables" --jq '.variables[] | select(.name == "G_AUTOMERGE_BOT_ID") | .name' 2> /dev/null | grep -q "G_AUTOMERGE_BOT_ID"; then
        echo "--> github_actions_variable.automerge_bot_id"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_variable.automerge_bot_id" "${repo}:G_AUTOMERGE_BOT_ID"
      fi

      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/variables" --jq '.variables[] | select(.name == "G_DOCKERHUB_USERNAME") | .name' 2> /dev/null | grep -q "G_DOCKERHUB_USERNAME"; then
        echo "--> github_actions_variable.dockerhub_username"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_variable.dockerhub_username" "${repo}:G_DOCKERHUB_USERNAME"
      fi

      ## secrets
      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/secrets" --jq '.secrets[] | select(.name == "G_BUMP_BOT_PRIVATEKEY") | .name' 2> /dev/null | grep -q "G_BUMP_BOT_PRIVATEKEY"; then
        echo "--> github_actions_secret.bump_bot_privatekey"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_secret.bump_bot_privatekey" "${repo}/G_BUMP_BOT_PRIVATEKEY"
      fi

      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/secrets" --jq '.secrets[] | select(.name == "G_AUTOMERGE_BOT_PRIVATEKEY") | .name' 2> /dev/null | grep -q "G_AUTOMERGE_BOT_PRIVATEKEY"; then
        echo "--> github_actions_secret.automerge_bot_privatekey"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_secret.automerge_bot_privatekey" "${repo}/G_AUTOMERGE_BOT_PRIVATEKEY"
      fi

      if gh api "/repos/${GITHUB_OWNER}/${repo}/actions/secrets" --jq '.secrets[] | select(.name == "G_DOCKERHUB_TOKEN") | .name' 2> /dev/null | grep -q "G_DOCKERHUB_TOKEN"; then
        echo "--> github_actions_secret.dockerhub_token"
        tofu import \
          "module.repos[\"${repo}\"].github_actions_secret.dockerhub_token" "${repo}/G_DOCKERHUB_TOKEN"
      fi

    # Archived/Deleted -> state rm
    elif [[ ${annotate} == '< ' ]]; then
      echo "state rm: ${repo}"
      tofu state rm "module.repos[\"${repo}\"]"
    fi

done < ./tmp/repos.diff

echo "Step4: inject github job data to reviewers"
while read reponame
do
  repos_raw=$(cat repos.auto.tfvars.json)

  # get pr workflow_runs of latest commit
  latest_pr_runs_pr=$(get_latest_runs ${GITHUB_OWNER} ${reponame} pull_request)
  latest_pr_runs_prt=$(get_latest_runs ${GITHUB_OWNER} ${reponame} pull_request_target)
  latest_pr_runs_urls=$(echo $latest_pr_runs_pr $latest_pr_runs_prt \
    | jq -rs "sort_by(.updated_at) | reverse \
      | .[0].head_sha as \$first_sha \
      | .[] | select(.head_sha == \$first_sha) | .jobs_url")

  all_job_names=""
  if [[ -n "${latest_pr_runs_urls}" ]]; then
    for runs_url in ${latest_pr_runs_urls}
    do
      job_names=$(gh api ${runs_url} | jq -r "[.jobs[] | .name] | @json")
      if [[ ${all_job_names} == "" ]]; then
          all_job_names=${job_names}
      else
          all_job_names="${all_job_names},${job_names}"
      fi
    done
  fi
  if [[ -n "${all_job_names}" ]]; then
    all_job_names_array=$(echo "[${all_job_names}]" | jq 'add | unique')
    target_index=$(echo ${repos_raw} | jq -r ".repos | map(.name == \"${reponame}\") | index(true)")
    echo ${repos_raw} | jq ".repos[${target_index}].pr_job_names += ${all_job_names_array}" > repos.auto.tfvars.json
  fi

done < ./tmp/repo_names_gh
