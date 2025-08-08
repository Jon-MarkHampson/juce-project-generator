# JUCE Project Generator

A comprehensive bash script for generating JUCE audio plugin projects with CMake and modern C++ standards.

## Features

- **Interactive Setup**: Guides you through project configuration with validation
- **Multiple Plugin Formats**: VST3, AU, AAX, Standalone, Unity
- **Testing Support**: Optional GoogleTest integration
- **Modern C++ Standards**: C++23 by default
- **CMake + CPM**: Modern CMake setup with CPM package manager
- **IDE Support**: Automatic VS Code configuration
- **Template Files**: Copies JUCE example templates or creates minimal ones
- **Documentation**: Generates README.md file

## Prerequisites

- CMake 3.22 or higher
- wget or curl
- Git
- C++23 compatible compiler

## Platform Support

### macOS/Linux
```bash
./create-juce-project.sh
```

### Windows
Three options:
1. **PowerShell (Native)**: Use `create-juce-project.ps1`
   ```powershell
   .\create-juce-project.ps1
   ```

2. **WSL (Windows Subsystem for Linux)**: Use the bash script
   ```bash
   ./create-juce-project.sh
   ```

3. **Git Bash**: Use the bash script (may need modifications)
   ```bash
   ./create-juce-project.sh
   ```

The script will interactively ask for:

1. **Project Location** (NEW!):
   - Auto-detects if you're in the juce-project-generator directory
   - Offers smart defaults (parent directory when in generator folder)
   - Options: Parent dir, Current dir, or Custom path
   - Shows full path before creation

2. **Project Information**:
   - Project directory name
   - Project name
   - Product name (display name)
   - Company name
   - Company code (4 uppercase letters)
   - Plugin code (4 uppercase letters)

3. **Plugin Configuration**:
   - Plugin formats (VST3, AU, AAX, Standalone, Unity)
   - Whether it's a synthesizer
   - MIDI input/output requirements

4. **Dependencies**:
   - JUCE version (default: 8.0.8)
   - GoogleTest inclusion and version (default: v1.17.0)

## Generated Project Structure

```
your_project/
├── CMakeLists.txt              # Root CMake configuration
├── README.md                   # Project documentation
├── .gitignore                  # Git ignore file
├── compile_commands.json       # Symlink for IDE support
├── cmake/
│   └── cpm.cmake              # CPM package manager
├── plugin/
│   ├── CMakeLists.txt         # Plugin CMake configuration
│   ├── include/
│   │   └── YourProject/
│   │       ├── PluginProcessor.h
│   │       └── PluginEditor.h
│   └── source/
│       ├── PluginProcessor.cpp
│       └── PluginEditor.cpp
├── test/                       # (Optional)
│   ├── CMakeLists.txt
│   └── source/
│       └── PluginProcessorTest.cpp
├── libs/                       # Dependencies (managed by CPM)
│   ├── juce/
│   └── googletest/            # (Optional)
├── build/                      # Build directory (created by CMake)
└── .vscode/                    # VS Code configuration
    ├── c_cpp_properties.json
    └── settings.json
```

## Example Usage

When run from the juce-project-generator directory:
```
$ ./create-juce-project.sh
=========================================
    JUCE Audio Plugin Project Generator
=========================================

[INFO] Detected you're in the juce-project-generator directory.
Where would you like to create your project?
1) Parent directory: /Users/yourname/Development
2) Current directory: /Users/yourname/Development/juce-project-generator  
3) Custom path
Enter choice (1/2/3) [default: 1]: 1

Enter project directory name (e.g., my_awesome_plugin): my_reverb_plugin
Enter project name (e.g., MyAwesomePlugin): MyReverb
...
[SUCCESS] Project 'MyReverb' created successfully!
Project location: /Users/yourname/Development/my_reverb_plugin
```

## Building Generated Projects

After running the generator:

```bash
# Navigate to your new project (path shown in generator output)
cd /Users/yourname/Development/my_reverb_plugin

# Configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Run tests (if included)
cd build && ctest --output-on-failure
```

## Script Features

### Smart Project Location
- Auto-detects if running from juce-project-generator directory
- Defaults to parent directory to keep your workspace organized
- Flexible options: parent dir, current dir, or custom path
- Shows full path before creating project

### Input Validation
- Validates project names (alphanumeric + underscore)
- Validates plugin codes (4 uppercase letters)
- Checks for existing directories
- Verifies dependency versions

### Smart Defaults
- Default location: parent directory when in generator folder
- Default JUCE version: 8.0.8
- Default GoogleTest version: v1.17.0
- Default formats: VST3 and AU (VST3 and Standalone on Windows)
- Automatically adds 'v' prefix to GoogleTest versions

### Error Handling
- Exits on errors with clear messages
- Color-coded output for clarity
- Warnings for unverified versions

### IDE Support
- Generates compile_commands.json
- VS Code configuration for C++23
- Platform-specific IntelliSense settings

## Customization

You can modify the script to:
- Change default versions
- Add more plugin format options
- Include additional dependencies
- Customize template files
- Add platform-specific configurations

## Troubleshooting

### Build Fails After Generation
- Ensure CMake 3.22+ is installed
- Check compiler supports C++23
- Verify internet connection for downloading dependencies

### JUCE Templates Not Found
- The script will create minimal templates if JUCE examples aren't found
- Templates are fully functional but basic

### Permission Denied
- Make sure the script is executable: `chmod +x create-juce-project.sh`

## License

This generator script is provided as-is for creating JUCE projects.

## Contributing

Feel free to submit issues or pull requests to improve the generator.