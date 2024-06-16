set shell := ["bash", "-c"]

# Help
default:
  @just --list --list-heading '' --list-prefix ''

# Copy a command that will run the stats script in the correct directory
@stats:
  @echo -n "cd $PWD && .scripts/stats.nu " | pbcopy
