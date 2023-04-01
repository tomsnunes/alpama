
param (
    [Parameter(Mandatory)][string][ValidateSet('llama','alpaca','gpt-2','gpt4all')]$model="llama",
    [Parameter(Mandatory)][string][ValidateSet('7b','13b')]$params="7b",
    [Parameter()][string]$profile=$model,
    [Parameter()][string][ValidateSet('alpaca','chat-with-bob', 'dan', 'doctor', 'reason-act')]$prompt,
    [Parameter()][bool]$perplexity=$false
)

# Set the default paths
$modelsFolder = "C:/.ai/.models"
$profilesFolder = "./profiles"
$promptsFolder = "./prompts"
$datasetsFolder = "./datasets"

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
$config = @{}
Get-Content "$profilesFolder/$profile.ini" | ForEach-Object {
    # Skip comments and empty lines
    if ($_ -notmatch "^\s*(#|;|$)") {
        $key, $value = $_ -split "=", 2
        $config[$key.Trim()] = $value.Trim()
    }
}

Write-Host "PROFILE: $configProfile.ini"
Write-Host "DEBUG: Initial config: $($config | Out-String)"

# Define the options for the main program
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
        Write-Host $option
        if ($($option) -ne "model") {
            $command += " --$option $($config[$option])"
        } else {
            $command += " --$option $modelsFolder/$model/$params/$($config[$option])"
        }
    
        if ($option -eq "prompt") {
            $command += " --file $promptFolder/$($config[$option])"
        } 
    }
}

# If a prompt file is specified on the command line, use it instead of the default
if ($prompt -ne "") {
    $command += " --file $promptsFolder/$prompt.txt"
}

# Run the command
Write-Host $command
Invoke-Expression $command
