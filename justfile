_default:
  just --list

_terragrunt action target debug="false":
  #!/usr/bin/env bash
  cd {{target}}
  if [ "{{debug}}" = "--debug" ]; then
    export TF_LOG=DEBUG
  fi

  if [ "{{action}}" = "destroy" ]; then
    terragrunt {{action}} --all 
  else
    # terragrunt will ask you if you want to apply dependencies
    # terragrunt {{action}} --all 

    # not asked, but if a non-applied dependency is found, the cmd will fail
    terragrunt {{action}} --non-interactive --all 

    # every dependency will be planned/applied automatically?
    # this can destroy dependencies!!
    # terragrunt {{action}} --non-interactive --terragrunt-include-external-dependencies --all 
  fi

_PROJ_ROOT := `pwd`

# plan: just plan $(pwd) --debug
plan target debug="false":
  just _terragrunt plan {{target}} {{debug}}

# apply: just apply $(pwd)
apply target debug="false":
  just _terragrunt apply {{target}} {{debug}}

# destroy a target: just destroy $(pwd)
destroy target debug="false":
  just _terragrunt destroy {{target}} {{debug}}

# enter the console to inspect TF
console target:
  just _terragrunt console {{target}}

# clear .terragrunt-cache dirs
clear-caches target=_PROJ_ROOT:
  #!/usr/bin/env bash
  cd {{target}}
  find . -type d -name '.terragrunt-cache' -prune -exec rm -rf {} \;
  echo "cleared"

# clear .terragrunt-lock files (useful when you change provider version)
clear-locks target=_PROJ_ROOT:
  #!/usr/bin/env bash
  cd {{target}}
  find . -name '.terraform.lock.hcl' -prune -exec rm -rf {} \;
  echo "cleared"

# clear both
clear-both target=_PROJ_ROOT:
  #!/usr/bin/env bash
  cd {{target}}
  find . -type d -name '.terragrunt-cache' -prune -exec rm -rf {} \;
  find . -name '.terraform.lock.hcl' -prune -exec rm -rf {} \;
  echo "cleared locks and caches"

# clear both terragrunt caches and locks
clear target=_PROJ_ROOT:
  just clear-caches {{target}}
  just clear-locks {{target}}

# format HCL
format:
  terraform fmt -recursive .
  terragrunt hcl fmt
