# Secrets and variables used in the CI build scripts

## Intro

As you can see in the `standard-build.yml` provided with each build flavour, we don't re-list all the secrets and variables our scripts need any more, having introduced the [secrets-to-env-action](https://github.com/oNaiPs/secrets-to-env-action), which does it for us (you).

As you can see in the provided standard workflow files ([example](python-poetry/standard-build.yml)), the action is used like this:

```yaml
# Avoids re-listing all the secrets again. As they recommend, use the commit hash to point to 
# an exact version, using tags might be compromised by malicious commits.
#
# See knetminer-ci docs for a list of secrets and other variables we use.
#
- name: Forward all GH secrets to env
	uses: oNaiPs/secrets-to-env-action@75f319b3c8c926ac2eabcca34daa6cf531daf32f # 1.8
	with:
		secrets: ${{ toJSON(secrets) }}
```


So, we document what the scripts expect here, and also in flavour-specific docs. In other words, here we list those secrets/variables that all the flavours use, additional ones are listed in the specific docs ([example](java-maven/secrets-n-variables.md)).

**WARNING**: additionally, the `secrets-to-env-action` forwards `secrets` and `vars` only (we usually don't use the latter), it **does not** deal with other values, such as `github.event.inputs`. So, these are still listed in the workflow YAML files and they're documented there too.

Both general and specific values need to be set in your repository or your organisation.

## Common secrets and variables

```yaml
# This allows for the CI to notify failures to Slack, see _common.sh
CI_SLACK_API_NOTIFICATION_URL: ${{secrets.CI_SLACK_API_NOTIFICATION_URL}}

# Set it up with yours, used with auto-commits
# TODO: is this automatically available from some GHA vars?
GIT_USER_EMAIL: ${{secrets.GIT_USER_EMAIL}}

# This is only set when using the act tool, to tell certain script functions to behave 
# differently than usually (eg, some extra packages need to be installed on a act runner)
# When using act, you need to set this somewhere like a secrets file. If set, it should 
# be 'true' or 'false'. I couldn't find any other way to detect 'act'.
CI_IS_ACT_TOOL: ${{ secrets.CI_IS_ACT_TOOL }}
# If CI_IS_ACT_TOOL is set, then the common scripts will set GIT_PASSWORD to this value,
# which should come from the secrets passed to act. This is because act doesn't support
# GITHUB_TOKEN.
GH_TOKEN: ${{secrets.GITHUB_PAT}}

# A list of branches to be used for deploying or release operations. If this worflow is
# run against a branch not listed here, deployment operations (eg, PyPI/Maven publishing)
# will be skipped and releasing will be blocked with an error.
# Note that you can exclude a branch from running a CI build using the GHA 'branches' option
# (see above).
CI_DEPLOY_BRANCHES: ${{ secrets.CI_DEPLOY_BRANCHES }}
```