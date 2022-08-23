# git-commit-audit
This bash script will "audit" the status of git commit signatures:

* Works on local or remote git repositories
* Shows statistics for the whole repo by default
* Optionally will show statistics for all individual contributors

## Usage Documentation

Get help

```
git-commit-audit.sh -h
```

Run in local directory that has git repo:

```
git-commit-audit.sh
```

Audity repo and get statistics on individual developers:

```
git-commit-audit.sh -d
```

Audit a remote repository:

```
git-commit-audit.sh -r https://github.com/facebook/react.git
```

Audit a remote repository and get developer stats:

```
git-commit-audit.sh -d -r https://github.com/facebook/react.git
```

## What the output looks like:
![Not particularily encouraging](git-commit-audit-termgrab.png)

## Sponsors 
Sponsored with 💜  by

<a href="https://securestack.com" target=”_blank” rel="noopener noreferrer"><center><img src="https://securestack.com/wp-content/uploads/2021/09/securestack-horizontal.png" width="500"/></center></a>


