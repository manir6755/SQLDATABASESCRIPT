# CodeStream Scale Sql Azure Database DevOps Task

### Publishing new version of extension

To generate new `.vsix` file for publishing do the following:

* Update `version` attribute in `vss-extension.json` file
* Update `version` attribute in task.json file
* run `tfx extension create --manifest-globs vss-extension.json`