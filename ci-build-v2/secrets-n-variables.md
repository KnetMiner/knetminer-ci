# Secrets and variables used in the CI build scripts

## Intro

As you can see in the `standard-build.yml` provided with each build flavour, we don't re-list all the secrets and variables our scripts need any more. Rather, we use this trick to forward all of them automatically:

```yaml
- name: Forward secrets to env vars
	env:
		_SECRETS_JS_STR: ${{ toJSON(secrets) }}
	run: |
		echo "$_SECRETS_JS_STR" | jq -r 'to_entries[] | "\(.key)<<EOF\n\(.value)\nEOF"' >> $GITHUB_ENV    
```

*(here-documents are used to suppport multi-line secrets, eg, SSH keys)*

Before this, we have attempted to use [secrets-to-env-action](https://github.com/oNaiPs/secrets-to-env-action), which does the same in a cleaner way, but unfortunately it doesn't work with the [act tool](https://nektosact.com/).

**WARNING**: this practice **might be unsafe**, since it might pass down secrets that your repo doesn't need to know, thus violating the principle of least privilege. While we use it in a controlled context (small organisation, few secrets, all of them almost always needed), you should be careful with doing the same. The alternative approach is going back to listing the secrets mentioned in our documentation (any any other you might need) in your workflow YAML, in the `env` section of our `build.sh` run step.

Since this approach has made all the secrets and variables that our framework needs, we list them in this document and in flavour-specific docs. Namely, here we list those secrets/variables that all the flavours use, additional ones are listed in the specific docs ([example](java-maven/secrets-n-variables.md)).

**WARNING**: the forward action above deals with `secrets` only (we usually don't use the variables), it **does not** work with other values, such as `github.event.inputs`. So, these are still listed in the workflow YAML files and they're documented there too. TODO: maybe add those too?

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
ACT_GIT_PASSWORD: ${{ secrets.ACT_GIT_PASSWORD }}

# Used during releasing by the GH client, to create a new release on the repo
# TODO: what's the difference with github.GITHUB_TOKEN? Since they should be the same,
# the CI scripts set it to GIT_PASSWORD if it's omitted. That should work.
GH_TOKEN: ${{secrets.token}}

# A list of branches to be used for deploying or release operations. If this worflow is
# run against a branch not listed here, deployment operations (eg, PyPI/Maven publishing)
# will be skipped and releasing will be blocked with an error.
# Note that you can exclude a branch from running a CI build using the GHA 'branches' option
# (see above).
CI_DEPLOY_BRANCHES: ${{ secrets.CI_DEPLOY_BRANCHES }}
```