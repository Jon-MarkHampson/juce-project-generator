#!/bin/bash

# JUCE Audio Plugin Project Generator
# Creates a CMake-based JUCE plugin project with proper structure

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to validate input
validate_input() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    # Check for valid characters (alphanumeric and underscore)
    if [[ "$1" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        return 0
    fi
    return 1
}

# Function to validate plugin code (4 chars)
validate_plugin_code() {
    if [[ ${#1} -eq 4 ]] && [[ "$1" =~ ^[A-Z]{4}$ ]]; then
        return 0
    fi
    return 1
}

# Welcome message
echo "========================================="
echo "    JUCE Audio Plugin Project Generator"
echo "========================================="
echo ""

# Determine where to create the project
CURRENT_DIR=$(pwd)
CURRENT_DIR_NAME=$(basename "$CURRENT_DIR")
PARENT_DIR=$(dirname "$CURRENT_DIR")

# Check if we're in the juce-project-generator directory
if [[ "$CURRENT_DIR_NAME" == "juce-project-generator" ]]; then
    print_info "Detected you're in the juce-project-generator directory."
    echo "Where would you like to create your project?"
    echo "1) Parent directory: $PARENT_DIR"
    echo "2) Current directory: $CURRENT_DIR"
    echo "3) Custom path"
    read -p "Enter choice (1/2/3) [default: 1]: " LOCATION_CHOICE
    LOCATION_CHOICE=${LOCATION_CHOICE:-1}
    
    case $LOCATION_CHOICE in
        1)
            PROJECT_BASE_DIR="$PARENT_DIR"
            ;;
        2)
            PROJECT_BASE_DIR="$CURRENT_DIR"
            ;;
        3)
            read -p "Enter full path to parent directory: " PROJECT_BASE_DIR
            # Expand tilde if present
            PROJECT_BASE_DIR="${PROJECT_BASE_DIR/#\~/$HOME}"
            if [[ ! -d "$PROJECT_BASE_DIR" ]]; then
                print_error "Directory '$PROJECT_BASE_DIR' does not exist!"
                exit 1
            fi
            ;;
        *)
            PROJECT_BASE_DIR="$PARENT_DIR"
            ;;
    esac
else
    # Not in juce-project-generator, ask where to create
    echo "Where would you like to create your project?"
    echo "1) Current directory: $CURRENT_DIR"
    echo "2) Custom path"
    read -p "Enter choice (1/2) [default: 1]: " LOCATION_CHOICE
    LOCATION_CHOICE=${LOCATION_CHOICE:-1}
    
    case $LOCATION_CHOICE in
        1)
            PROJECT_BASE_DIR="$CURRENT_DIR"
            ;;
        2)
            read -p "Enter full path to parent directory: " PROJECT_BASE_DIR
            # Expand tilde if present
            PROJECT_BASE_DIR="${PROJECT_BASE_DIR/#\~/$HOME}"
            if [[ ! -d "$PROJECT_BASE_DIR" ]]; then
                print_error "Directory '$PROJECT_BASE_DIR' does not exist!"
                exit 1
            fi
            ;;
        *)
            PROJECT_BASE_DIR="$CURRENT_DIR"
            ;;
    esac
fi

# Get project information from user
read -p "Enter project directory name (e.g., my_awesome_plugin): " PROJECT_DIR
while ! validate_input "$PROJECT_DIR"; do
    print_error "Invalid directory name. Use only letters, numbers, and underscores."
    read -p "Enter project directory name: " PROJECT_DIR
done

# Full path to project
FULL_PROJECT_PATH="$PROJECT_BASE_DIR/$PROJECT_DIR"

# Check if directory exists
if [[ -d "$FULL_PROJECT_PATH" ]]; then
    print_error "Directory '$FULL_PROJECT_PATH' already exists!"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" != "y" ]] && [[ "$OVERWRITE" != "Y" ]]; then
        print_info "Exiting..."
        exit 0
    fi
    rm -rf "$FULL_PROJECT_PATH"
fi

read -p "Enter project name (e.g., MyAwesomePlugin): " PROJECT_NAME
while ! validate_input "$PROJECT_NAME"; do
    print_error "Invalid project name. Use only letters, numbers, and underscores."
    read -p "Enter project name: " PROJECT_NAME
done

read -p "Enter product name (e.g., 'My Awesome Plugin'): " PRODUCT_NAME
while [[ -z "$PRODUCT_NAME" ]]; do
    print_error "Product name cannot be empty."
    read -p "Enter product name: " PRODUCT_NAME
done

read -p "Enter company name (e.g., MyCompany): " COMPANY_NAME
while ! validate_input "$COMPANY_NAME"; do
    print_error "Invalid company name. Use only letters, numbers, and underscores."
    read -p "Enter company name: " COMPANY_NAME
done

read -p "Enter company code (4 uppercase letters, e.g., MYCO): " COMPANY_CODE
while ! validate_plugin_code "$COMPANY_CODE"; do
    print_error "Invalid company code. Must be exactly 4 uppercase letters."
    read -p "Enter company code: " COMPANY_CODE
done

read -p "Enter plugin code (4 uppercase letters, e.g., PLUG): " PLUGIN_CODE
while ! validate_plugin_code "$PLUGIN_CODE"; do
    print_error "Invalid plugin code. Must be exactly 4 uppercase letters."
    read -p "Enter plugin code: " PLUGIN_CODE
done

# Plugin configuration
echo ""
print_info "Plugin Configuration"
echo "-------------------"

# Plugin formats
echo "Select plugin formats (space-separated numbers):"
echo "1) VST3"
echo "2) AU (Audio Unit - macOS only)"
echo "3) AAX"
echo "4) Standalone"
echo "5) Unity"
read -p "Enter choices (e.g., '1 2' for VST3 and AU): " FORMAT_CHOICES

FORMATS=""
for choice in $FORMAT_CHOICES; do
    case $choice in
        1) FORMATS="$FORMATS VST3" ;;
        2) FORMATS="$FORMATS AU" ;;
        3) FORMATS="$FORMATS AAX" ;;
        4) FORMATS="$FORMATS Standalone" ;;
        5) FORMATS="$FORMATS Unity" ;;
    esac
done
FORMATS=$(echo $FORMATS | xargs)  # Trim whitespace
if [[ -z "$FORMATS" ]]; then
    FORMATS="VST3 AU"
    print_warning "No formats selected. Using default: VST3 AU"
fi

# Plugin type
read -p "Is this a synthesizer? (y/N): " IS_SYNTH
if [[ "$IS_SYNTH" == "y" ]] || [[ "$IS_SYNTH" == "Y" ]]; then
    IS_SYNTH="TRUE"
    NEEDS_MIDI_INPUT="TRUE"
else
    IS_SYNTH="FALSE"
    read -p "Does this plugin need MIDI input? (y/N): " NEEDS_MIDI
    if [[ "$NEEDS_MIDI" == "y" ]] || [[ "$NEEDS_MIDI" == "Y" ]]; then
        NEEDS_MIDI_INPUT="TRUE"
    else
        NEEDS_MIDI_INPUT="FALSE"
    fi
fi

read -p "Does this plugin produce MIDI output? (y/N): " NEEDS_MIDI_OUT
if [[ "$NEEDS_MIDI_OUT" == "y" ]] || [[ "$NEEDS_MIDI_OUT" == "Y" ]]; then
    NEEDS_MIDI_OUTPUT="TRUE"
else
    NEEDS_MIDI_OUTPUT="FALSE"
fi

# Check for dependencies versions
echo ""
print_info "Checking dependencies..."

# JUCE version
DEFAULT_JUCE_VERSION="8.0.8"
read -p "Enter JUCE version (default: $DEFAULT_JUCE_VERSION): " JUCE_VERSION
JUCE_VERSION=${JUCE_VERSION:-$DEFAULT_JUCE_VERSION}

# Verify JUCE version exists
print_info "Verifying JUCE version $JUCE_VERSION..."
if curl -s -f -I "https://github.com/juce-framework/JUCE/releases/tag/$JUCE_VERSION" > /dev/null 2>&1; then
    print_success "JUCE version $JUCE_VERSION found"
else
    print_warning "Could not verify JUCE version $JUCE_VERSION. Proceeding anyway..."
fi

# GoogleTest version
read -p "Include GoogleTest for unit testing? (Y/n): " INCLUDE_TESTS
if [[ "$INCLUDE_TESTS" != "n" ]] && [[ "$INCLUDE_TESTS" != "N" ]]; then
    INCLUDE_TESTS="TRUE"
    DEFAULT_GTEST_VERSION="v1.17.0"
    read -p "Enter GoogleTest version (default: $DEFAULT_GTEST_VERSION): " GTEST_VERSION
    GTEST_VERSION=${GTEST_VERSION:-$DEFAULT_GTEST_VERSION}
    
    # Ensure 'v' prefix for GoogleTest
    if [[ ! "$GTEST_VERSION" =~ ^v ]]; then
        GTEST_VERSION="v$GTEST_VERSION"
    fi
    
    print_info "Verifying GoogleTest version $GTEST_VERSION..."
    if curl -s -f -I "https://github.com/google/googletest/releases/tag/$GTEST_VERSION" > /dev/null 2>&1; then
        print_success "GoogleTest version $GTEST_VERSION found"
    else
        print_warning "Could not verify GoogleTest version $GTEST_VERSION. Proceeding anyway..."
    fi
else
    INCLUDE_TESTS="FALSE"
fi

# Create project structure
echo ""
print_info "Creating project structure in: $FULL_PROJECT_PATH"

mkdir -p "$FULL_PROJECT_PATH"
cd "$FULL_PROJECT_PATH"

# Create directory structure
mkdir -p cmake
mkdir -p plugin/source
mkdir -p plugin/include/${PROJECT_NAME}
mkdir -p libs

if [[ "$INCLUDE_TESTS" == "TRUE" ]]; then
    mkdir -p test/source
fi

# Download CPM
print_info "Downloading CPM package manager..."
wget -q -O cmake/cpm.cmake https://github.com/cpm-cmake/CPM.cmake/releases/latest/download/get_cpm.cmake
print_success "CPM downloaded"

# Create root CMakeLists.txt
print_info "Creating root CMakeLists.txt..."
cat > CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.22)

project(${PROJECT_NAME})

set(CMAKE_CXX_STANDARD 23)

set(LIB_DIR \${CMAKE_CURRENT_SOURCE_DIR}/libs)
include(cmake/cpm.cmake)

CPMAddPackage(
    NAME JUCE
    GITHUB_REPOSITORY juce-framework/JUCE
    GIT_TAG ${JUCE_VERSION}
    VERSION ${JUCE_VERSION}
    SOURCE_DIR \${LIB_DIR}/juce
)

EOF

if [[ "$INCLUDE_TESTS" == "TRUE" ]]; then
    cat >> CMakeLists.txt << EOF
CPMAddPackage(
    NAME GOOGLETEST
    GITHUB_REPOSITORY google/googletest
    GIT_TAG ${GTEST_VERSION}
    VERSION ${GTEST_VERSION#v}
    SOURCE_DIR \${LIB_DIR}/googletest
    OPTIONS
        "INSTALL_GTEST OFF"
        "gtest_force_shared_crt ON"
)

enable_testing()

EOF
fi

cat >> CMakeLists.txt << EOF
if (MSVC)
    add_compile_options(/Wall /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

add_subdirectory(plugin)
EOF

if [[ "$INCLUDE_TESTS" == "TRUE" ]]; then
    echo "add_subdirectory(test)" >> CMakeLists.txt
fi

# Create plugin CMakeLists.txt
print_info "Creating plugin CMakeLists.txt..."
cat > plugin/CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.22)

project(${PROJECT_NAME}Plugin VERSION 0.1.0)

juce_add_plugin(\${PROJECT_NAME}
    VERSION \${PROJECT_VERSION}
    COMPANY_NAME ${COMPANY_NAME}
    PLUGIN_MANUFACTURER_CODE ${COMPANY_CODE}
    PRODUCT_NAME "${PRODUCT_NAME}"
    PLUGIN_CODE ${PLUGIN_CODE}
    FORMATS ${FORMATS}
    IS_SYNTH ${IS_SYNTH}
    NEEDS_MIDI_INPUT ${NEEDS_MIDI_INPUT}
    NEEDS_MIDI_OUTPUT ${NEEDS_MIDI_OUTPUT}
)

target_sources(\${PROJECT_NAME}
    PRIVATE
        source/PluginProcessor.cpp
        source/PluginEditor.cpp
)

target_include_directories(\${PROJECT_NAME}
    PRIVATE
        include
)

target_link_libraries(\${PROJECT_NAME}
    PRIVATE
        juce::juce_audio_utils
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags
)

target_compile_definitions(\${PROJECT_NAME}
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
)

if(MSVC)
    target_compile_definitions(\${PROJECT_NAME}
        PRIVATE
            _SILENCE_CXX23_ALIGNED_STORAGE_DEPRECATION_WARNING
    )
endif()
EOF

# Create test CMakeLists.txt if needed
if [[ "$INCLUDE_TESTS" == "TRUE" ]]; then
    print_info "Creating test CMakeLists.txt..."
    cat > test/CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.22)

project(${PROJECT_NAME}Tests)

add_executable(\${PROJECT_NAME}
    source/PluginProcessorTest.cpp
)

target_include_directories(\${PROJECT_NAME}
    PRIVATE
        \${CMAKE_SOURCE_DIR}/plugin/include
)

target_link_libraries(\${PROJECT_NAME}
    PRIVATE
        ${PROJECT_NAME}Plugin
        GTest::gtest
        GTest::gtest_main
        juce::juce_audio_utils
)

# Register tests with CTest
include(GoogleTest)
gtest_discover_tests(\${PROJECT_NAME})
EOF

    # Create sample test file
    print_info "Creating sample test file..."
    # Create lowercase version for namespace (portable)
    PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
    cat > test/source/PluginProcessorTest.cpp << EOF
#include <gtest/gtest.h>
#include "${PROJECT_NAME}/PluginProcessor.h"

namespace ${PROJECT_NAME_LOWER}_test {

TEST(AudioPluginAudioProcessor, CanBeInstantiated) {
    AudioPluginAudioProcessor processor{};
    ASSERT_TRUE(processor.getName().isNotEmpty());
}

TEST(AudioPluginAudioProcessor, HasCorrectInitialState) {
    AudioPluginAudioProcessor processor{};
    EXPECT_FALSE(processor.acceptsMidi());
    EXPECT_FALSE(processor.producesMidi());
    EXPECT_EQ(processor.getTailLengthSeconds(), 0.0);
}

} // namespace ${PROJECT_NAME_LOWER}_test
EOF
fi

# Create README.md
print_info "Creating README.md..."
cat > README.md << EOF
# ${PRODUCT_NAME}

A JUCE-based audio plugin project.

## Building

### Prerequisites
- CMake 3.22 or higher
- C++23 compatible compiler
- macOS: Xcode 13+ 
- Windows: Visual Studio 2022
- Linux: GCC 11+ or Clang 14+

### Build Instructions

\`\`\`bash
# Configure the project
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Build the project
cmake --build build

# Run tests (if included)
cd build && ctest --output-on-failure
\`\`\`

### Build Configurations
- Debug: \`cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug\`
- Release: \`cmake -S . -B build -DCMAKE_BUILD_TYPE=Release\`

## Project Structure
- \`/plugin/\` - Main plugin source code
- \`/test/\` - Unit tests (if included)
- \`/libs/\` - Dependencies (managed by CPM)
- \`/cmake/\` - CMake utilities

## Plugin Information
- **Company**: ${COMPANY_NAME}
- **Plugin Code**: ${PLUGIN_CODE}
- **Formats**: ${FORMATS}
- **Type**: $([ "$IS_SYNTH" == "TRUE" ] && echo "Synthesizer" || echo "Audio Effect")

## License
[Add your license here]
EOF

# Create .gitignore
print_info "Creating .gitignore..."
cat > .gitignore << 'EOF'
# Build directories
build/
cmake-build-*/
out/

# Dependencies
libs/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Compiled binaries
*.component/
*.vst3/
*.vst/
*.aaxplugin/
*.app/

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json
CTestTestfile.cmake
_deps/

# CPM
cpm-package-lock.cmake
EOF


# Create initial template files (required for CMake to work)
print_info "Creating initial template files..."

# Create minimal PluginProcessor.h
cat > plugin/include/${PROJECT_NAME}/PluginProcessor.h << 'EOPROCESSORH'
#pragma once

#include <juce_audio_processors/juce_audio_processors.h>

class AudioPluginAudioProcessor final : public juce::AudioProcessor
{
public:
    AudioPluginAudioProcessor();
    ~AudioPluginAudioProcessor() override;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;
    using AudioProcessor::processBlock;
    
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;
    
    const juce::String getName() const override;
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;
    
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;
    
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

private:
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AudioPluginAudioProcessor)
};
EOPROCESSORH

# Create minimal PluginEditor.h
cat > plugin/include/${PROJECT_NAME}/PluginEditor.h << 'EOEDITORH'
#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include "PluginProcessor.h"

class AudioPluginAudioProcessorEditor final : public juce::AudioProcessorEditor
{
public:
    explicit AudioPluginAudioProcessorEditor (AudioPluginAudioProcessor&);
    ~AudioPluginAudioProcessorEditor() override;

    void paint (juce::Graphics&) override;
    void resized() override;

private:
    AudioPluginAudioProcessor& processorRef;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AudioPluginAudioProcessorEditor)
};
EOEDITORH

# Create PluginProcessor.cpp
cat > plugin/source/PluginProcessor.cpp << EOF
#include "${PROJECT_NAME}/PluginProcessor.h"
#include "${PROJECT_NAME}/PluginEditor.h"

AudioPluginAudioProcessor::AudioPluginAudioProcessor()
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
{
}

AudioPluginAudioProcessor::~AudioPluginAudioProcessor()
{
}

const juce::String AudioPluginAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool AudioPluginAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool AudioPluginAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool AudioPluginAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double AudioPluginAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int AudioPluginAudioProcessor::getNumPrograms()
{
    return 1;
}

int AudioPluginAudioProcessor::getCurrentProgram()
{
    return 0;
}

void AudioPluginAudioProcessor::setCurrentProgram (int index)
{
    juce::ignoreUnused (index);
}

const juce::String AudioPluginAudioProcessor::getProgramName (int index)
{
    juce::ignoreUnused (index);
    return {};
}

void AudioPluginAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
    juce::ignoreUnused (index, newName);
}

void AudioPluginAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    juce::ignoreUnused (sampleRate, samplesPerBlock);
}

void AudioPluginAudioProcessor::releaseResources()
{
}

bool AudioPluginAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}

void AudioPluginAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer,
                                              juce::MidiBuffer& midiMessages)
{
    juce::ignoreUnused (midiMessages);

    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    // Process audio here
    for (int channel = 0; channel < totalNumInputChannels; ++channel)
    {
        auto* channelData = buffer.getWritePointer (channel);
        juce::ignoreUnused (channelData);
    }
}

bool AudioPluginAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* AudioPluginAudioProcessor::createEditor()
{
    return new AudioPluginAudioProcessorEditor (*this);
}

void AudioPluginAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    juce::ignoreUnused (destData);
}

void AudioPluginAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    juce::ignoreUnused (data, sizeInBytes);
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new AudioPluginAudioProcessor();
}
EOF

# Create PluginEditor.cpp
cat > plugin/source/PluginEditor.cpp << EOF
#include "${PROJECT_NAME}/PluginProcessor.h"
#include "${PROJECT_NAME}/PluginEditor.h"

AudioPluginAudioProcessorEditor::AudioPluginAudioProcessorEditor (AudioPluginAudioProcessor& p)
    : AudioProcessorEditor (&p), processorRef (p)
{
    juce::ignoreUnused (processorRef);
    setSize (400, 300);
}

AudioPluginAudioProcessorEditor::~AudioPluginAudioProcessorEditor()
{
}

void AudioPluginAudioProcessorEditor::paint (juce::Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawFittedText ("${PRODUCT_NAME}", getLocalBounds(), juce::Justification::centred, 1);
}

void AudioPluginAudioProcessorEditor::resized()
{
}
EOF

print_success "Initial template files created"

# Initial configuration to download JUCE
print_info "Downloading JUCE framework..."
echo -n "  Configuring CMake..."
if cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > /dev/null 2>&1; then
    echo " ✓"
else
    echo " ✗"
    print_error "CMake configuration failed. Please check your CMake installation."
    exit 1
fi

# Wait for JUCE to be downloaded with progress indicator
echo -n "  Waiting for JUCE download"
WAIT_COUNT=0
while [ ! -d "libs/juce/examples/CMake/AudioPlugin" ] && [ $WAIT_COUNT -lt 60 ]; do
    echo -n "."
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done
echo " ✓"

# Copy template files from JUCE examples
print_info "Setting up plugin template files..."

if [ -d "libs/juce/examples/CMake/AudioPlugin" ]; then
    echo -n "  Copying headers..."
    # Copy header files
    cp libs/juce/examples/CMake/AudioPlugin/PluginProcessor.h plugin/include/${PROJECT_NAME}/ 2>/dev/null || true
    cp libs/juce/examples/CMake/AudioPlugin/PluginEditor.h plugin/include/${PROJECT_NAME}/ 2>/dev/null || true
    echo " ✓"
    
    echo -n "  Copying source files..."
    # Copy source files
    cp libs/juce/examples/CMake/AudioPlugin/PluginProcessor.cpp plugin/source/ 2>/dev/null || true
    cp libs/juce/examples/CMake/AudioPlugin/PluginEditor.cpp plugin/source/ 2>/dev/null || true
    echo " ✓"
    
    # Update includes in source files (cross-platform sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|#include \"PluginProcessor.h\"|#include \"${PROJECT_NAME}/PluginProcessor.h\"|g" plugin/source/PluginProcessor.cpp
        sed -i '' "s|#include \"PluginEditor.h\"|#include \"${PROJECT_NAME}/PluginEditor.h\"|g" plugin/source/PluginProcessor.cpp
        sed -i '' "s|#include \"PluginProcessor.h\"|#include \"${PROJECT_NAME}/PluginProcessor.h\"|g" plugin/source/PluginEditor.cpp
        sed -i '' "s|#include \"PluginEditor.h\"|#include \"${PROJECT_NAME}/PluginEditor.h\"|g" plugin/source/PluginEditor.cpp
    else
        # Linux
        sed -i "s|#include \"PluginProcessor.h\"|#include \"${PROJECT_NAME}/PluginProcessor.h\"|g" plugin/source/PluginProcessor.cpp
        sed -i "s|#include \"PluginEditor.h\"|#include \"${PROJECT_NAME}/PluginEditor.h\"|g" plugin/source/PluginProcessor.cpp
        sed -i "s|#include \"PluginProcessor.h\"|#include \"${PROJECT_NAME}/PluginProcessor.h\"|g" plugin/source/PluginEditor.cpp
        sed -i "s|#include \"PluginEditor.h\"|#include \"${PROJECT_NAME}/PluginEditor.h\"|g" plugin/source/PluginEditor.cpp
    fi
    
    print_success "Template files upgraded with JUCE examples"
else
    print_info "JUCE examples not found. Using minimal templates created earlier."
    
    # Create minimal PluginProcessor.h
    cat > plugin/include/${PROJECT_NAME}/PluginProcessor.h << 'EOF'
#pragma once

#include <juce_audio_processors/juce_audio_processors.h>

class AudioPluginAudioProcessor final : public juce::AudioProcessor
{
public:
    AudioPluginAudioProcessor();
    ~AudioPluginAudioProcessor() override;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;
    using AudioProcessor::processBlock;
    
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;
    
    const juce::String getName() const override;
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;
    
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;
    
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

private:
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AudioPluginAudioProcessor)
};
EOF

    # Create minimal PluginEditor.h
    cat > plugin/include/${PROJECT_NAME}/PluginEditor.h << 'EOF'
#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include "PluginProcessor.h"

class AudioPluginAudioProcessorEditor final : public juce::AudioProcessorEditor
{
public:
    explicit AudioPluginAudioProcessorEditor (AudioPluginAudioProcessor&);
    ~AudioPluginAudioProcessorEditor() override;

    void paint (juce::Graphics&) override;
    void resized() override;

private:
    AudioPluginAudioProcessor& processorRef;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AudioPluginAudioProcessorEditor)
};
EOF

    # Create PluginProcessor.cpp
    cat > plugin/source/PluginProcessor.cpp << EOF
#include "${PROJECT_NAME}/PluginProcessor.h"
#include "${PROJECT_NAME}/PluginEditor.h"

AudioPluginAudioProcessor::AudioPluginAudioProcessor()
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
{
}

AudioPluginAudioProcessor::~AudioPluginAudioProcessor()
{
}

const juce::String AudioPluginAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool AudioPluginAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool AudioPluginAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool AudioPluginAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double AudioPluginAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int AudioPluginAudioProcessor::getNumPrograms()
{
    return 1;
}

int AudioPluginAudioProcessor::getCurrentProgram()
{
    return 0;
}

void AudioPluginAudioProcessor::setCurrentProgram (int index)
{
    juce::ignoreUnused (index);
}

const juce::String AudioPluginAudioProcessor::getProgramName (int index)
{
    juce::ignoreUnused (index);
    return {};
}

void AudioPluginAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
    juce::ignoreUnused (index, newName);
}

void AudioPluginAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    juce::ignoreUnused (sampleRate, samplesPerBlock);
}

void AudioPluginAudioProcessor::releaseResources()
{
}

bool AudioPluginAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}

void AudioPluginAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer,
                                              juce::MidiBuffer& midiMessages)
{
    juce::ignoreUnused (midiMessages);

    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    // Process audio here
    for (int channel = 0; channel < totalNumInputChannels; ++channel)
    {
        auto* channelData = buffer.getWritePointer (channel);
        juce::ignoreUnused (channelData);
    }
}

bool AudioPluginAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* AudioPluginAudioProcessor::createEditor()
{
    return new AudioPluginAudioProcessorEditor (*this);
}

void AudioPluginAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    juce::ignoreUnused (destData);
}

void AudioPluginAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    juce::ignoreUnused (data, sizeInBytes);
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new AudioPluginAudioProcessor();
}
EOF

    # Create PluginEditor.cpp
    cat > plugin/source/PluginEditor.cpp << EOF
#include "${PROJECT_NAME}/PluginProcessor.h"
#include "${PROJECT_NAME}/PluginEditor.h"

AudioPluginAudioProcessorEditor::AudioPluginAudioProcessorEditor (AudioPluginAudioProcessor& p)
    : AudioProcessorEditor (&p), processorRef (p)
{
    juce::ignoreUnused (processorRef);
    setSize (400, 300);
}

AudioPluginAudioProcessorEditor::~AudioPluginAudioProcessorEditor()
{
}

void AudioPluginAudioProcessorEditor::paint (juce::Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawFittedText ("${PRODUCT_NAME}", getLocalBounds(), juce::Justification::centred, 1);
}

void AudioPluginAudioProcessorEditor::resized()
{
}
EOF
fi

# Create VS Code configuration
print_info "Creating VS Code configuration..."
mkdir -p .vscode

cat > .vscode/c_cpp_properties.json << 'EOF'
{
    "configurations": [
        {
            "name": "Mac",
            "compileCommands": "${workspaceFolder}/compile_commands.json",
            "cStandard": "c17",
            "cppStandard": "c++23",
            "intelliSenseMode": "macos-clang-arm64",
            "configurationProvider": "ms-vscode.cmake-tools"
        },
        {
            "name": "Win32",
            "compileCommands": "${workspaceFolder}/compile_commands.json",
            "cStandard": "c17",
            "cppStandard": "c++23",
            "intelliSenseMode": "windows-msvc-x64",
            "configurationProvider": "ms-vscode.cmake-tools"
        },
        {
            "name": "Linux",
            "compileCommands": "${workspaceFolder}/compile_commands.json",
            "cStandard": "c17",
            "cppStandard": "c++23",
            "intelliSenseMode": "linux-gcc-x64",
            "configurationProvider": "ms-vscode.cmake-tools"
        }
    ],
    "version": 4
}
EOF

cat > .vscode/settings.json << 'EOF'
{
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
    "cmake.configureOnOpen": true,
    "cmake.buildDirectory": "${workspaceFolder}/build",
    "files.associations": {
        "*.mm": "cpp",
        "*.h": "cpp"
    }
}
EOF

# Create symlink for compile_commands.json
ln -sf build/compile_commands.json compile_commands.json

# Initialize git repository
print_info "Initializing Git repository..."
echo -n "  Creating repository..."
git init -q
echo " ✓"

echo -n "  Adding files..."
git add -A
echo " ✓"

echo -n "  Creating initial commit..."
git commit -q -m "Initial commit: ${PRODUCT_NAME} - JUCE audio plugin project

Generated with juce-project-generator
- Plugin formats: ${FORMATS}
- JUCE version: ${JUCE_VERSION}
$([ "$INCLUDE_TESTS" == "TRUE" ] && echo "- Testing: GoogleTest ${GTEST_VERSION}")"
echo " ✓"

# Build and test the project
print_info "Verifying project setup..."
echo -n "  Building plugin..."
if cmake --build build --parallel > /dev/null 2>&1; then
    echo " ✓"
    BUILD_SUCCESS=true
else
    echo " ✗"
    BUILD_SUCCESS=false
fi

# Run tests if included and build succeeded
if [[ "$INCLUDE_TESTS" == "TRUE" ]] && [[ "$BUILD_SUCCESS" == "true" ]]; then
    echo -n "  Running tests..."
    if (cd build && ctest --output-on-failure > /dev/null 2>&1); then
        echo " ✓"
        TEST_SUCCESS=true
    else
        echo " ✗"
        TEST_SUCCESS=false
    fi
fi

# Summary with visual feedback
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    PROJECT CREATION COMPLETE                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_success "✨ Project '${PRODUCT_NAME}' created successfully!"
echo ""
echo "📁 Location: ${GREEN}$FULL_PROJECT_PATH${NC}"
echo ""
echo "📋 Project Details:"
echo "   • Project Name: ${PROJECT_NAME}"
echo "   • Company: ${COMPANY_NAME} (${COMPANY_CODE})"
echo "   • Plugin Code: ${PLUGIN_CODE}"
echo "   • Formats: ${FORMATS}"
echo "   • JUCE Version: ${JUCE_VERSION}"
$([ "$INCLUDE_TESTS" == "TRUE" ] && echo "   • Testing: GoogleTest ${GTEST_VERSION}")
echo ""
echo "🔧 Build Status:"
if [[ "$BUILD_SUCCESS" == "true" ]]; then
    echo "   ${GREEN}✓${NC} Plugin builds successfully"
    if [[ "$INCLUDE_TESTS" == "TRUE" ]]; then
        if [[ "$TEST_SUCCESS" == "true" ]]; then
            echo "   ${GREEN}✓${NC} All tests pass"
        else
            echo "   ${YELLOW}⚠${NC} Tests failed - check test configuration"
        fi
    fi
else
    echo "   ${YELLOW}⚠${NC} Build needs configuration - see instructions below"
fi
echo ""
echo "📖 Next Steps:"
echo "   ${BLUE}1.${NC} cd $FULL_PROJECT_PATH"
echo "   ${BLUE}2.${NC} code .  ${YELLOW}# Open in VS Code${NC}"
echo "   ${BLUE}3.${NC} Start developing your plugin!"
echo ""
echo "🚀 Quick Commands:"
echo "   Build:  ${GREEN}cmake --build build${NC}"
echo "   Clean:  ${GREEN}cmake --build build --target clean${NC}"
$([ "$INCLUDE_TESTS" == "TRUE" ] && echo "   Test:   ${GREEN}cd build && ctest --output-on-failure${NC}")
echo "   Debug:  ${GREEN}cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug${NC}"
echo ""
print_info "Happy coding! 🎵"
echo ""