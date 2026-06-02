# Self-build scripts

This are used by the CI framework itself, to perform simple build tasks, such as tagging the repo with a new release upon request.

For now, the only useful thing that the [build script in this 'flavour'](build.sh) does to our own repo is managing the creation of a new release tag. That's why we don't run this script at every push (see .github/workflows/self-build.yml).
