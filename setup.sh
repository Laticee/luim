#!/bin/bash

# Luim Setup Script
# Compiles the driver and creates a global command

echo "Setting up Luim..."

# Get absolute path of the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Compile the driver
echo "Compiling input driver..."
lune run "$DIR/build.luau"

if [ $? -ne 0 ]; then
    echo "Error: Failed to compile the driver."
    exit 1
fi

# Create the wrapper script
echo "Creating global command 'luim'..."

WRAPPER="/usr/local/bin/luim"

cat <<EOF > luim_wrapper
#!/bin/bash
export LUIM_DIR="$DIR"
lune run "\$LUIM_DIR/main.luau" "\$@"
EOF

# Move to /usr/local/bin (requires sudo if not owner)
if [ -w "/usr/local/bin" ]; then
    mv luim_wrapper "$WRAPPER"
    chmod +x "$WRAPPER"
else
    echo "Permission denied for /usr/local/bin. Trying with sudo..."
    sudo mv luim_wrapper "$WRAPPER"
    sudo chmod +x "$WRAPPER"
fi

echo "Done! You can now run 'luim' from anywhere."
echo "Note: Ensure 'lune' is in your PATH."
