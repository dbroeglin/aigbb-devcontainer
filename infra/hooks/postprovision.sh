#!/usr/bin/env bash
set -euo pipefail # exit on error, undefined variable, and error in pipeline
[ -n "${DEBUG:-}" ] && set -x # enable debug mode if DEBUG is set

printf "\n  🪝 \033[32mRunning postprovision hook...\033[0m\n"

# Insert your code here

# AZD environment variables are available as shell environment variables:
#
# echo -e "  \033[32mAZD_ENVIRONMENT_NAME: ${AZD_ENVIRONMENT_NAME}\033[0m"
#
# Here are some other examples of what you can do in hook scripts:
#
# Finish setting up Entra ID authentication by


printf "  🪝 \033[32mFinished postprovision hook.\033[0m\n\n"

# Everything is fine, exit with 0
exit 0
