# JUCE Audio Plugin Project Generator for Windows
# Creates a CMake-based JUCE plugin project with proper structure

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "JUCE Project Generator - Creates a new JUCE audio plugin project"
    Write-Host "Usage: .\create-juce-project.ps1"
    exit 0
}

# Color functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# Function to validate input
function Test-ValidInput {
    param([string]$Input)
    return $Input -match '^[a-zA-Z][a-zA-Z0-9_]*$'
}

# Function to validate plugin code (4 chars)
function Test-ValidPluginCode {
    param([string]$Code)
    return ($Code.Length -eq 4) -and ($Code -match '^[A-Z]{4}$')
}

# Welcome message
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    JUCE Audio Plugin Project Generator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Determine where to create the project
$CURRENT_DIR = Get-Location
$CURRENT_DIR_NAME = Split-Path -Leaf $CURRENT_DIR
$PARENT_DIR = Split-Path -Parent $CURRENT_DIR

# Check if we're in the juce-project-generator directory
if ($CURRENT_DIR_NAME -eq "juce-project-generator") {
    Write-Info "Detected you're in the juce-project-generator directory."
    Write-Host "Where would you like to create your project?"
    Write-Host "1) Parent directory: $PARENT_DIR"
    Write-Host "2) Current directory: $CURRENT_DIR"
    Write-Host "3) Custom path"
    $LOCATION_CHOICE = Read-Host "Enter choice (1/2/3) [default: 1]"
    if ([string]::IsNullOrWhiteSpace($LOCATION_CHOICE)) {
        $LOCATION_CHOICE = "1"
    }
    
    switch ($LOCATION_CHOICE) {
        "1" { $PROJECT_BASE_DIR = $PARENT_DIR }
        "2" { $PROJECT_BASE_DIR = $CURRENT_DIR }
        "3" {
            $PROJECT_BASE_DIR = Read-Host "Enter full path to parent directory"
            # Expand environment variables and resolve path
            $PROJECT_BASE_DIR = [System.Environment]::ExpandEnvironmentVariables($PROJECT_BASE_DIR)
            if (-not (Test-Path $PROJECT_BASE_DIR)) {
                Write-Error "Directory '$PROJECT_BASE_DIR' does not exist!"
                exit 1
            }
        }
        default { $PROJECT_BASE_DIR = $PARENT_DIR }
    }
} else {
    # Not in juce-project-generator, ask where to create
    Write-Host "Where would you like to create your project?"
    Write-Host "1) Current directory: $CURRENT_DIR"
    Write-Host "2) Custom path"
    $LOCATION_CHOICE = Read-Host "Enter choice (1/2) [default: 1]"
    if ([string]::IsNullOrWhiteSpace($LOCATION_CHOICE)) {
        $LOCATION_CHOICE = "1"
    }
    
    switch ($LOCATION_CHOICE) {
        "1" { $PROJECT_BASE_DIR = $CURRENT_DIR }
        "2" {
            $PROJECT_BASE_DIR = Read-Host "Enter full path to parent directory"
            # Expand environment variables and resolve path
            $PROJECT_BASE_DIR = [System.Environment]::ExpandEnvironmentVariables($PROJECT_BASE_DIR)
            if (-not (Test-Path $PROJECT_BASE_DIR)) {
                Write-Error "Directory '$PROJECT_BASE_DIR' does not exist!"
                exit 1
            }
        }
        default { $PROJECT_BASE_DIR = $CURRENT_DIR }
    }
}

# Get project information from user
do {
    $PROJECT_DIR = Read-Host "Enter project directory name (e.g., my_awesome_plugin)"
} while (-not (Test-ValidInput $PROJECT_DIR))

# Full path to project
$FULL_PROJECT_PATH = Join-Path $PROJECT_BASE_DIR $PROJECT_DIR

# Check if directory exists
if (Test-Path $FULL_PROJECT_PATH) {
    Write-Error "Directory '$FULL_PROJECT_PATH' already exists!"
    $OVERWRITE = Read-Host "Do you want to overwrite it? (y/N)"
    if ($OVERWRITE -ne "y" -and $OVERWRITE -ne "Y") {
        Write-Info "Exiting..."
        exit 0
    }
    Remove-Item -Recurse -Force $FULL_PROJECT_PATH
}

do {
    $PROJECT_NAME = Read-Host "Enter project name (e.g., MyAwesomePlugin)"
} while (-not (Test-ValidInput $PROJECT_NAME))

do {
    $PRODUCT_NAME = Read-Host "Enter product name (e.g., 'My Awesome Plugin')"
} while ([string]::IsNullOrWhiteSpace($PRODUCT_NAME))

do {
    $COMPANY_NAME = Read-Host "Enter company name (e.g., MyCompany)"
} while (-not (Test-ValidInput $COMPANY_NAME))

do {
    $COMPANY_CODE = Read-Host "Enter company code (4 uppercase letters, e.g., MYCO)"
} while (-not (Test-ValidPluginCode $COMPANY_CODE))

do {
    $PLUGIN_CODE = Read-Host "Enter plugin code (4 uppercase letters, e.g., PLUG)"
} while (-not (Test-ValidPluginCode $PLUGIN_CODE))

# Plugin configuration
Write-Host ""
Write-Info "Plugin Configuration"
Write-Host "-------------------"

# Plugin formats
Write-Host "Select plugin formats (space-separated numbers):"
Write-Host "1) VST3"
Write-Host "2) AU (Audio Unit - macOS only)"
Write-Host "3) AAX"
Write-Host "4) Standalone"
Write-Host "5) Unity"
$FORMAT_CHOICES = Read-Host "Enter choices (e.g., '1 4' for VST3 and Standalone)"

$FORMATS = @()
foreach ($choice in $FORMAT_CHOICES.Split(' ')) {
    switch ($choice) {
        "1" { $FORMATS += "VST3" }
        "2" { $FORMATS += "AU" }
        "3" { $FORMATS += "AAX" }
        "4" { $FORMATS += "Standalone" }
        "5" { $FORMATS += "Unity" }
    }
}
if ($FORMATS.Count -eq 0) {
    $FORMATS = @("VST3", "Standalone")
    Write-Warning "No formats selected. Using default: VST3 Standalone"
}
$FORMATS_STRING = $FORMATS -join " "

# Plugin type
$IS_SYNTH_INPUT = Read-Host "Is this a synthesizer? (y/N)"
if ($IS_SYNTH_INPUT -eq "y" -or $IS_SYNTH_INPUT -eq "Y") {
    $IS_SYNTH = "TRUE"
    $NEEDS_MIDI_INPUT = "TRUE"
} else {
    $IS_SYNTH = "FALSE"
    $NEEDS_MIDI = Read-Host "Does this plugin need MIDI input? (y/N)"
    if ($NEEDS_MIDI -eq "y" -or $NEEDS_MIDI -eq "Y") {
        $NEEDS_MIDI_INPUT = "TRUE"
    } else {
        $NEEDS_MIDI_INPUT = "FALSE"
    }
}

$NEEDS_MIDI_OUT = Read-Host "Does this plugin produce MIDI output? (y/N)"
if ($NEEDS_MIDI_OUT -eq "y" -or $NEEDS_MIDI_OUT -eq "Y") {
    $NEEDS_MIDI_OUTPUT = "TRUE"
} else {
    $NEEDS_MIDI_OUTPUT = "FALSE"
}

# Check for dependencies versions
Write-Host ""
Write-Info "Checking dependencies..."

# JUCE version
$DEFAULT_JUCE_VERSION = "8.0.8"
$JUCE_VERSION = Read-Host "Enter JUCE version (default: $DEFAULT_JUCE_VERSION)"
if ([string]::IsNullOrWhiteSpace($JUCE_VERSION)) {
    $JUCE_VERSION = $DEFAULT_JUCE_VERSION
}

# Verify JUCE version exists
Write-Info "Verifying JUCE version $JUCE_VERSION..."
try {
    $response = Invoke-WebRequest -Uri "https://github.com/juce-framework/JUCE/releases/tag/$JUCE_VERSION" -Method Head -ErrorAction Stop
    Write-Success "JUCE version $JUCE_VERSION found"
} catch {
    Write-Warning "Could not verify JUCE version $JUCE_VERSION. Proceeding anyway..."
}

# GoogleTest version
$INCLUDE_TESTS_INPUT = Read-Host "Include GoogleTest for unit testing? (Y/n)"
if ($INCLUDE_TESTS_INPUT -ne "n" -and $INCLUDE_TESTS_INPUT -ne "N") {
    $INCLUDE_TESTS = "TRUE"
    $DEFAULT_GTEST_VERSION = "v1.17.0"
    $GTEST_VERSION = Read-Host "Enter GoogleTest version (default: $DEFAULT_GTEST_VERSION)"
    if ([string]::IsNullOrWhiteSpace($GTEST_VERSION)) {
        $GTEST_VERSION = $DEFAULT_GTEST_VERSION
    }
    
    # Ensure 'v' prefix for GoogleTest
    if (-not $GTEST_VERSION.StartsWith("v")) {
        $GTEST_VERSION = "v$GTEST_VERSION"
    }
    
    Write-Info "Verifying GoogleTest version $GTEST_VERSION..."
    try {
        $response = Invoke-WebRequest -Uri "https://github.com/google/googletest/releases/tag/$GTEST_VERSION" -Method Head -ErrorAction Stop
        Write-Success "GoogleTest version $GTEST_VERSION found"
    } catch {
        Write-Warning "Could not verify GoogleTest version $GTEST_VERSION. Proceeding anyway..."
    }
} else {
    $INCLUDE_TESTS = "FALSE"
}

# Create project structure
Write-Host ""
Write-Info "Creating project structure in: $FULL_PROJECT_PATH"

New-Item -ItemType Directory -Force -Path $FULL_PROJECT_PATH | Out-Null
Set-Location $FULL_PROJECT_PATH

# Create directory structure
New-Item -ItemType Directory -Force -Path "cmake" | Out-Null
New-Item -ItemType Directory -Force -Path "plugin/source" | Out-Null
New-Item -ItemType Directory -Force -Path "plugin/include/$PROJECT_NAME" | Out-Null
New-Item -ItemType Directory -Force -Path "libs" | Out-Null

if ($INCLUDE_TESTS -eq "TRUE") {
    New-Item -ItemType Directory -Force -Path "test/source" | Out-Null
}

# Download CPM
Write-Info "Downloading CPM package manager..."
Invoke-WebRequest -Uri "https://github.com/cpm-cmake/CPM.cmake/releases/latest/download/get_cpm.cmake" -OutFile "cmake/cpm.cmake"
Write-Success "CPM downloaded"

# Create root CMakeLists.txt
Write-Info "Creating root CMakeLists.txt..."
@"
cmake_minimum_required(VERSION 3.22)

project($PROJECT_NAME)

set(CMAKE_CXX_STANDARD 23)

set(LIB_DIR `${CMAKE_CURRENT_SOURCE_DIR}/libs)
include(cmake/cpm.cmake)

CPMAddPackage(
    NAME JUCE
    GITHUB_REPOSITORY juce-framework/JUCE
    GIT_TAG $JUCE_VERSION
    VERSION $JUCE_VERSION
    SOURCE_DIR `${LIB_DIR}/juce
)

"@ | Out-File -Encoding UTF8 "CMakeLists.txt"

if ($INCLUDE_TESTS -eq "TRUE") {
    $GTEST_VERSION_NO_V = $GTEST_VERSION.TrimStart('v')
    @"
CPMAddPackage(
    NAME GOOGLETEST
    GITHUB_REPOSITORY google/googletest
    GIT_TAG $GTEST_VERSION
    VERSION $GTEST_VERSION_NO_V
    SOURCE_DIR `${LIB_DIR}/googletest
    OPTIONS
        "INSTALL_GTEST OFF"
        "gtest_force_shared_crt ON"
)

enable_testing()

"@ | Out-File -Encoding UTF8 -Append "CMakeLists.txt"
}

@"
if (MSVC)
    add_compile_options(/Wall /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

add_subdirectory(plugin)
"@ | Out-File -Encoding UTF8 -Append "CMakeLists.txt"

if ($INCLUDE_TESTS -eq "TRUE") {
    "add_subdirectory(test)" | Out-File -Encoding UTF8 -Append "CMakeLists.txt"
}

# Create plugin CMakeLists.txt
Write-Info "Creating plugin CMakeLists.txt..."
@"
cmake_minimum_required(VERSION 3.22)

project(${PROJECT_NAME}Plugin VERSION 0.1.0)

juce_add_plugin(`${PROJECT_NAME}
    VERSION `${PROJECT_VERSION}
    COMPANY_NAME $COMPANY_NAME
    PLUGIN_MANUFACTURER_CODE $COMPANY_CODE
    PRODUCT_NAME "$PRODUCT_NAME"
    PLUGIN_CODE $PLUGIN_CODE
    FORMATS $FORMATS_STRING
    IS_SYNTH $IS_SYNTH
    NEEDS_MIDI_INPUT $NEEDS_MIDI_INPUT
    NEEDS_MIDI_OUTPUT $NEEDS_MIDI_OUTPUT
)

target_sources(`${PROJECT_NAME}
    PRIVATE
        source/PluginProcessor.cpp
        source/PluginEditor.cpp
)

target_include_directories(`${PROJECT_NAME}
    PRIVATE
        include
)

target_link_libraries(`${PROJECT_NAME}
    PRIVATE
        juce::juce_audio_utils
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags
)

target_compile_definitions(`${PROJECT_NAME}
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
)

if(MSVC)
    target_compile_definitions(`${PROJECT_NAME}
        PRIVATE
            _SILENCE_CXX23_ALIGNED_STORAGE_DEPRECATION_WARNING
    )
endif()
"@ | Out-File -Encoding UTF8 "plugin/CMakeLists.txt"

# Create test CMakeLists.txt if needed
if ($INCLUDE_TESTS -eq "TRUE") {
    Write-Info "Creating test CMakeLists.txt..."
    @"
cmake_minimum_required(VERSION 3.22)

project(${PROJECT_NAME}Tests)

add_executable(`${PROJECT_NAME}
    source/PluginProcessorTest.cpp
)

target_include_directories(`${PROJECT_NAME}
    PRIVATE
        `${CMAKE_SOURCE_DIR}/plugin/include
)

target_link_libraries(`${PROJECT_NAME}
    PRIVATE
        ${PROJECT_NAME}Plugin
        GTest::gtest
        GTest::gtest_main
        juce::juce_audio_utils
)

# Register tests with CTest
include(GoogleTest)
gtest_discover_tests(`${PROJECT_NAME})
"@ | Out-File -Encoding UTF8 "test/CMakeLists.txt"

    # Create sample test file
    Write-Info "Creating sample test file..."
    @"
#include <gtest/gtest.h>
#include "$PROJECT_NAME/PluginProcessor.h"

namespace ${PROJECT_NAME}_test {

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

} // namespace ${PROJECT_NAME}_test
"@ | Out-File -Encoding UTF8 "test/source/PluginProcessorTest.cpp"
}

# Create initial template files FIRST (required for CMake to work)
Write-Info "Creating initial template files..."

# PluginProcessor.h
@"
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
"@ | Out-File -Encoding UTF8 "plugin/include/$PROJECT_NAME/PluginProcessor.h"

# PluginEditor.h
@"
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
"@ | Out-File -Encoding UTF8 "plugin/include/$PROJECT_NAME/PluginEditor.h"

# Create source files
Write-Info "Creating source files..."

# PluginProcessor.cpp
@"
#include "$PROJECT_NAME/PluginProcessor.h"
#include "$PROJECT_NAME/PluginEditor.h"

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
"@ | Out-File -Encoding UTF8 "plugin/source/PluginProcessor.cpp"

# PluginEditor.cpp
@"
#include "$PROJECT_NAME/PluginProcessor.h"
#include "$PROJECT_NAME/PluginEditor.h"

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
    g.drawFittedText ("$PRODUCT_NAME", getLocalBounds(), juce::Justification::centred, 1);
}

void AudioPluginAudioProcessorEditor::resized()
{
}
"@ | Out-File -Encoding UTF8 "plugin/source/PluginEditor.cpp"

Write-Success "Initial template files created"

# Initial configuration to download JUCE
Write-Info "Downloading JUCE framework..."
Write-Host -NoNewline "  Configuring CMake..."
$ConfigResult = Start-Process cmake -ArgumentList "-S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON" -NoNewWindow -Wait -PassThru
if ($ConfigResult.ExitCode -eq 0) {
    Write-Host " ✓" -ForegroundColor Green
} else {
    Write-Host " ✗" -ForegroundColor Red
    Write-Error "CMake configuration failed. Please check your CMake installation."
    exit 1
}

# Wait for JUCE to be downloaded with progress indicator
Write-Host -NoNewline "  Waiting for JUCE download"
$WaitCount = 0
while ((-not (Test-Path "libs/juce/examples/CMake/AudioPlugin")) -and ($WaitCount -lt 60)) {
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
    $WaitCount++
}
Write-Host " ✓" -ForegroundColor Green

# Copy template files from JUCE examples if available
Write-Info "Setting up plugin template files..."

if (Test-Path "libs/juce/examples/CMake/AudioPlugin") {
    Write-Host -NoNewline "  Copying headers..."
    Copy-Item -Path "libs/juce/examples/CMake/AudioPlugin/PluginProcessor.h" -Destination "plugin/include/$PROJECT_NAME/" -ErrorAction SilentlyContinue
    Copy-Item -Path "libs/juce/examples/CMake/AudioPlugin/PluginEditor.h" -Destination "plugin/include/$PROJECT_NAME/" -ErrorAction SilentlyContinue
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Host -NoNewline "  Copying source files..."
    Copy-Item -Path "libs/juce/examples/CMake/AudioPlugin/PluginProcessor.cpp" -Destination "plugin/source/" -ErrorAction SilentlyContinue
    Copy-Item -Path "libs/juce/examples/CMake/AudioPlugin/PluginEditor.cpp" -Destination "plugin/source/" -ErrorAction SilentlyContinue
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Host -NoNewline "  Updating includes..."
    # Update includes in source files
    $ProcessorContent = Get-Content "plugin/source/PluginProcessor.cpp" -Raw
    $ProcessorContent = $ProcessorContent -replace '#include "PluginProcessor.h"', "#include `"$PROJECT_NAME/PluginProcessor.h`""
    $ProcessorContent = $ProcessorContent -replace '#include "PluginEditor.h"', "#include `"$PROJECT_NAME/PluginEditor.h`""
    Set-Content -Path "plugin/source/PluginProcessor.cpp" -Value $ProcessorContent -Encoding UTF8
    
    $EditorContent = Get-Content "plugin/source/PluginEditor.cpp" -Raw
    $EditorContent = $EditorContent -replace '#include "PluginProcessor.h"', "#include `"$PROJECT_NAME/PluginProcessor.h`""
    $EditorContent = $EditorContent -replace '#include "PluginEditor.h"', "#include `"$PROJECT_NAME/PluginEditor.h`""
    Set-Content -Path "plugin/source/PluginEditor.cpp" -Value $EditorContent -Encoding UTF8
    Write-Host " ✓" -ForegroundColor Green
    
    Write-Success "Template files upgraded with JUCE examples"
} else {
    Write-Info "JUCE examples not found. Using minimal templates created earlier."
}

# Create README.md and other files...
Write-Info "Creating documentation files..."

# Create .gitignore
@"
# Build directories
build/
cmake-build-*/
out/

# Dependencies
libs/

# IDE files
.vscode/
.vs/
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Compiled binaries
*.component/
*.vst3/
*.vst/
*.aaxplugin/
*.app/
*.exe
*.dll

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json
CTestTestfile.cmake
_deps/

# CPM
cpm-package-lock.cmake
"@ | Out-File -Encoding UTF8 ".gitignore"

# Initialize git repository
Write-Info "Initializing Git repository..."
Write-Host -NoNewline "  Creating repository..."
git init -q
Write-Host " ✓" -ForegroundColor Green

Write-Host -NoNewline "  Adding files..."
git add -A
Write-Host " ✓" -ForegroundColor Green

Write-Host -NoNewline "  Creating initial commit..."
$CommitMessage = "Initial commit: $PRODUCT_NAME - JUCE audio plugin project

Generated with juce-project-generator
- Plugin formats: $FORMATS_STRING
- JUCE version: $JUCE_VERSION"
if ($INCLUDE_TESTS -eq "TRUE") {
    $CommitMessage += "`n- Testing: GoogleTest $GTEST_VERSION"
}
git commit -q -m $CommitMessage
Write-Host " ✓" -ForegroundColor Green

# Build and test the project
Write-Info "Verifying project setup..."
Write-Host -NoNewline "  Building plugin..."
$BuildResult = Start-Process cmake -ArgumentList "--build build --parallel" -NoNewWindow -Wait -PassThru
if ($BuildResult.ExitCode -eq 0) {
    Write-Host " ✓" -ForegroundColor Green
    $BUILD_SUCCESS = $true
} else {
    Write-Host " ✗" -ForegroundColor Red
    $BUILD_SUCCESS = $false
}

# Run tests if included and build succeeded
if (($INCLUDE_TESTS -eq "TRUE") -and $BUILD_SUCCESS) {
    Write-Host -NoNewline "  Running tests..."
    Push-Location build
    $TestResult = Start-Process ctest -ArgumentList "--output-on-failure" -NoNewWindow -Wait -PassThru
    Pop-Location
    if ($TestResult.ExitCode -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
        $TEST_SUCCESS = $true
    } else {
        Write-Host " ✗" -ForegroundColor Red
        $TEST_SUCCESS = $false
    }
}

# Summary with visual feedback
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    PROJECT CREATION COMPLETE                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Success "✨ Project '$PRODUCT_NAME' created successfully!"
Write-Host ""
Write-Host "📁 Location: " -NoNewline
Write-Host "$FULL_PROJECT_PATH" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Project Details:"
Write-Host "   • Project Name: $PROJECT_NAME"
Write-Host "   • Company: $COMPANY_NAME ($COMPANY_CODE)"
Write-Host "   • Plugin Code: $PLUGIN_CODE"
Write-Host "   • Formats: $FORMATS_STRING"
Write-Host "   • JUCE Version: $JUCE_VERSION"
if ($INCLUDE_TESTS -eq "TRUE") {
    Write-Host "   • Testing: GoogleTest $GTEST_VERSION"
}
Write-Host ""
Write-Host "🔧 Build Status:"
if ($BUILD_SUCCESS) {
    Write-Host "   ✓ Plugin builds successfully" -ForegroundColor Green
    if ($INCLUDE_TESTS -eq "TRUE") {
        if ($TEST_SUCCESS) {
            Write-Host "   ✓ All tests pass" -ForegroundColor Green
        } else {
            Write-Host "   ⚠ Tests failed - check test configuration" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   ⚠ Build needs configuration - see instructions below" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "📖 Next Steps:"
Write-Host "   1. " -NoNewline
Write-Host "cd $FULL_PROJECT_PATH" -ForegroundColor Blue
Write-Host "   2. " -NoNewline
Write-Host "code . " -ForegroundColor Blue -NoNewline
Write-Host "  # Open in VS Code" -ForegroundColor Yellow
Write-Host "   3. Start developing your plugin!"
Write-Host ""
Write-Host "🚀 Quick Commands:"
Write-Host "   Build:  " -NoNewline
Write-Host "cmake --build build" -ForegroundColor Green
Write-Host "   Clean:  " -NoNewline
Write-Host "cmake --build build --target clean" -ForegroundColor Green
if ($INCLUDE_TESTS -eq "TRUE") {
    Write-Host "   Test:   " -NoNewline
    Write-Host "cd build; ctest --output-on-failure" -ForegroundColor Green
}
Write-Host "   Debug:  " -NoNewline
Write-Host "cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug" -ForegroundColor Green
Write-Host ""
Write-Info "Happy coding! 🎵"
Write-Host ""