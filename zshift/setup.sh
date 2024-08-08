#!/usr/bin/env zsh


# Find the directory where this script is located
SCRIPT_DIR="${0:a:h}"

# Change to the script directory
cd "$SCRIPT_DIR"

# Run the Swift script to create the symlink
cd ../zshift && swift run zshift link-zshrc

# Check if the symlink was created successfully
if [[ $? -eq 0 ]]; then
    # Source the new .zshrc
    source ~/.zshrc
    print -P "%F{green}Setup complete! Your .zshrc is now linked to the shared configuration.%f"
else
    print -P "%F{red}Error: Failed to create symlink. Please check the Swift script output.%f"
    exit 1
fi

# Optionally, we can add some checks here
if [[ -n $MONO_ROOT ]]; then
    print -P "%F{cyan}MONO_ROOT is set to: $MONO_ROOT%f"
else
    print -P "%F{yellow}Warning: MONO_ROOT is not set. Some functionalities might not work correctly.%f"
fi

# Maybe add a reminder for user-specific configurations
if [[ -f ~/.zshrc.local ]]; then
    print -P "%F{cyan}Don't forget: You have a ~/.zshrc.local file for machine-specific configurations.%f"
else
    print -P "%F{yellow}Tip: You can create a ~/.zshrc.local file for machine-specific configurations.%f"
fi
