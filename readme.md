
# Git-Based Semantic Versioning

Semver.sh is a bash script which attempts to solve a common chicken-and-egg
problem which can occur when using semantic versioning in automated builds.
When building an application, it is desirable to incorporate a semantic version
number for the build into the build itself. This value needs to be provided to
the build as an argument, however there are drawbacks to the obvious methods
for obtaining the value. Ideally we'd like to be able to determine the version
from the git repository alone without any additional state on the build server,
produce multiple preview iterations of the same version without knowing which
one will be selected for release, and increment a single number (major, minor or
patch) between each release, depending on the changes made between versions.

The solution provided by this script is to use branches to mark versions, then
calculate the next version based on the presence of major and minor markers in
git commit messages.

Operations in semver use two branches, a _root_ which by default is `master`,
and the most recent _branch_ matching the branch folder pattern. By default
this will be `release/*`. The semantic version provided is always calculated
as a change of one from the last root branch to the current branch. For release
versions, a count of commits to the branch is used (e.g. number of hotfix
commits applied).

Semver is released as public domain.

## Usage

Use the -o flag to indicate the type of output desired.

- `last`: the most recent version marked with a branch
- `next`: the next version for a new build by itself in `1.0.0` form
- `full`: the next version including build number like `1.0.0.0`, the last number is the number of changes on the root branch since the last release
- `release`: the full version in form such as `1.0.0+0`, the count here is the number of changes to the last release branch
- `preview`: the preview version like `1.0.0-preview1`
- `info`: displays a table with all version information

```
./semver.sh -o next
```

| Option         | Description 
| -------------- | --------------------------------------------------------- |
| -f --folder    | Specify the branch 'folder' to use, default is 'release'  |
| -o --output    | Sets the output type, required"                           |
| -m --minor     | Sets minor version keyword, default is `[MINOR]`          |
| -M --Major     | Sets major version keyword, default is `[MAJOR]`          |
| -p --preview   | Sets the preview version prefix, default is 'preview'     |
| --product      | Sets branch and keywords using namespace                  |