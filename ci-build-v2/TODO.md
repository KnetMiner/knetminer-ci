# New Common ci-build

## What next:
* Document it, this and all of jutils, linkml schema
	* Copy-paste `java-maven/build.sh` from projects that started using the new CI.
	* Same for the GHA YAML
* Review the bootstap:
  - OK the template (`build.sh.template`) should download and run `install.sh`, with customisations as parameters
	- OK and then it should run main
* Ubuntu cache? (Looks pretty complicated, when needed, a custom container might be an easier alternative)
* Track the projects that uses us (manually, dedicated file)

## Tests and CI for our own repo

* Build toy projects (for Maven and Poetry) and use them to test the CI workflows. Then, use them to define a CI build for the hereby repo. Currently, we don't have anything to build, apart from tagging with release tags.

* **But** having one workflow only to test multiple flavours is probably bad. So, explore having one WF per flavour, which would also allow for maintaining tested gihub actions YAML workflows (reusable as templates by clients).

## Plan to complete the migration to the new repo

* Finish things above, document usage, etc
* Start using it and possibly (ahah! :-) ) fix incoming issues

## ~~Plan to go back to main~~

**DEPRECATED**: we migrated to the hereby repo, we won't use the old one any more, just add a deprecation note in it and close the branch we have migrated from.

* Finish things above, document usage, etc
* Go back to main
* Documentation
* Release
* Update consumer projects with a URL that links to a stable version

## Improvements

* Functions like `stage_deploy()` should pass the deploy mode check to its extensions. Problem is it can't just return 1/false, cause this is confused with an actual failure. A possible solution is to adopt the convention to print "skip" as last operation, but then we need to redirect all the diagnostics to stderr.