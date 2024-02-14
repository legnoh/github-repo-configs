#!/bin/bash

set -e

GITHUB_API_URL=${GITHUB_API_URL:-"https://api.github.com"}
GITHUB_REPOSITORY_OWNER=${GITHUB_REPOSITORY_OWNER:?}
GITHUB_TOKEN=${GITHUB_TOKEN:?}

mkdir -p ./tmp

echo "Step1: Get GitHub Repositories"
gh repo list --no-archived --limit 1000 --json=name,defaultBranchRef,repositoryTopics,isEmpty,visibility \
  | jq "[sort_by(.name) | .[] \
      | select(.isEmpty == false and .visibility == \"PUBLIC\") \
      | .repositoryTopics |= if . != null then [.[].name] else [] end \
      | { name:.name, default_branch:.defaultBranchRef.name, topics:.repositoryTopics } \
    ] as \$res \
    | { repos: \$res }" > ./repos.auto.tfvars.json

cat ./repos.auto.tfvars.json | jq -r ".repos[].name" > ./tmp/repo_names_gh
if [[ $(cat ./tmp/repo_names_gh | wc -l) -eq 0 ]]; then
  echo "repo_names file is something wrong. exit."
  exit 1
fi

echo "Step2: Get repo info from terraform state"
terraform state list module.repos \
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
      terraform import "module.repos[\"${repo}\"].github_repository.repo" ${repo}
      terraform import "module.repos[\"${repo}\"].github_branch_default.main" ${repo}

    # Archived/Deleted -> state rm
    elif [[ ${annotate} == '< ' ]]; then
      echo "state rm: ${repo}"
      terraform state rm module.repos\[\"${repo}\"\]
    fi

done < ./tmp/repos.diff

echo "Step4: inject github job data to reviewers"
while read reponame
do
  # get pr workflow_runs of latest commit
  repos_raw=$(cat repos.auto.tfvars.json)
  latest_pr_runs_urls_pr=$(gh api "/repos/${GITHUB_REPOSITORY_OWNER}/${reponame}/actions/runs?event=pull_request" \
  | jq -r "[ .workflow_runs[] \
      | { name:.name, head_sha:.head_sha, jobs_url:.jobs_url }] as \$wf_runs \
    | \$wf_runs[0].head_sha as \$first_sha \
    | \$wf_runs[] | select(.head_sha == \$first_sha) | .jobs_url")
  latest_pr_runs_urls_prt=$(gh api "/repos/${GITHUB_REPOSITORY_OWNER}/${reponame}/actions/runs?event=pull_request_target" \
  | jq -r "[ .workflow_runs[] \
      | { name:.name, head_sha:.head_sha, jobs_url:.jobs_url }] as \$wf_runs \
    | \$wf_runs[0].head_sha as \$first_sha \
    | \$wf_runs[] | select(.head_sha == \$first_sha) | .jobs_url")
  latest_pr_runs_urls=$(printf '%s\n' ${latest_pr_runs_urls_pr} ${latest_pr_runs_urls_prt})

  all_job_names=""
  for runs_url in ${latest_pr_runs_urls}
  do
    job_names=$(gh api ${runs_url} | jq -r "[.jobs[].name] | @json")
    if [[ ${all_job_names} == "" ]]; then
        all_job_names=${job_names}
    else
        all_job_names="${all_job_names},${job_names}"
    fi
  done
  all_job_names_array=$(echo "[${all_job_names}]" | jq ". | add")
  target_index=$(echo ${repos_raw} | jq -r ".repos | map(.name == \"${reponame}\") | index(true)")
  echo ${repos_raw} | jq ".repos[${target_index}].pr_job_names += ${all_job_names_array}" > repos.auto.tfvars.json

done < ./tmp/repo_names_gh
