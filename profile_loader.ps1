
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    [ValidateSet('llama','alpaca','gpt-2','gpt4all')]
    $model="llama",

    [Parameter(Mandatory)]
    [string]
    [ValidateSet('7b','13b')]
    $params="7b",

    [Parameter()]
    [string]
    $profile=$model,

    [Parameter()]
    [string]
    [ValidateSet('alpaca','chat-with-bob', 'dan', 'doctor', 'reason-act')]
    $prompt,

    [Parameter()]
    [bool]
    $perplexity=$false
)

# Set default paths
$modelsFolder = "C:\.ai\.models"
$profilesFolder = Join-Path $PSScriptRoot "profiles"
$promptsFolder = Join-Path $PSScriptRoot "prompts"
$datasetsFolder = Join-Path $PSScriptRoot "datasets"

# Loads the proper binary for the operation
if ($perplexity) {
    $profile = "$model-perplexity"
    $binary = ".\bin\Release\perplexity.exe"   
    $dataset = "wikitext-2-raw"
    $perplexityTest = "wiki.test.raw"
    $command = $binary
    $command += " --file $datasetsFolder/$dataset/$perplexityTest"
} else {
    $binary = ".\bin\Release\main.exe"
    $command = $binary
}

# Load the configuration file as a hash table
try{
    $config = @{}
    Get-Content (Join-Path $profilesFolder "$profile.ini") -ErrorAction Stop | ForEach-Object {
        # Skip comments and empty lines
        if ($_ -notmatch "^\s*(#|;|$)") {
            $key, $value = $_ -split "=", 2
            $config[$key.Trim()] = $value.Trim()
        }
    }
    
} catch {
    Write-Error "An error occurred while reading the configuration file: $_"
    # Handle the error here
}

Write-Verbose "DEBUG: Initial config: $($config | Out-String)"

# Define the configuration file options
$options = @(
    "model",
    "color",
    "n_predict",
    "ctx_size",
    "top_k",
    "temp",
    "repeat_penalty",
    "threads",
    "instruct",
    "interactive",
    "reverse-prompt",
    "perplexity",
    "prompt"
)

# Build the command to run the main program with the configuration options
foreach ($option in $options) {
    if ($config.ContainsKey($option)) {
        Write-Verbose "Adding $option option with value $($config[$option])"
        
        if ($option -eq "model") {
            $command += " --$option $modelsFolder/$model/$params/$($config[$option])"
        } else {
            $command += " --$option $($config[$option])"
        }
        
        if ($option -eq "prompt" -and $prompt) {
            $command += " --file $promptsFolder/$($config[$option]).txt"
        }
    }
}

# Append prompt file path to the command if specified on the command line
if ($prompt -ne "") {
    $command += " --file $promptsFolder/$prompt.txt"
}

# Run the command
Write-Host $command
try {
    Invoke-Expression $command
}
catch {
    Write-Error "An error occurred while executing the main program with the following command: $command"
}

