
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    [ValidateSet('llama','alpaca','alpaca-lora','gpt-2','gpt4all','chatdoctor','vicuna','point-alpaca','gpt4-x-alpaca-native')]
    $modelName="llama",

    [Parameter()]
    [string]
    [ValidateSet('7b','13b','30b','65b','117m')]
    $modelParams="7b",

    [Parameter()]
    [string]
    $profileName=$modelName,

    [Parameter()]
    [string]
    [ValidateSet('alpaca','chat-with-bob', 'dan', 'chatdoctor', 'reason-act', 'chat-13b','vicuna')]
    $prompt,

    [Parameter()]
    [bool]
    $perplexity=$false
)
# Build definitions
$buildVariant = "Release" # Debug | Release
$buildTargetFolder = ".\bin"

$binaryPath = "$buildTargetFolder\$buildVariant"

# llama.cpp binaries
$mainBinary = "main.exe"
$perplexityBinary = "perplexity.exe"

# Set default paths
$modelsFolder   =  "C:\.ai\.models"
$profilesFolder =  "./profiles"
$promptsFolder  =  "./prompts"
$datasetsFolder =  "./datasets"

# Perplexity
$dataset = "wikitext-2-raw"
$perplexityTest = "wiki.test.raw"

# Loads the proper binary for the operation
if ($perplexity) {
    $profileName = "perplexity_$modelName"
    $command = "$binaryPath\$perplexityBinary"
    $command += " --file $datasetsFolder/$dataset/$perplexityTest"
} else {
    $command = "$binaryPath\$mainBinary"
}

# Load the configuration file as a hash table
try{
    $config = @{}
    Get-Content (Join-Path $profilesFolder "$profileName.ini") -ErrorAction Stop | ForEach-Object {
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
    "name",
    "model",
    "prompt",
    "color",
    "n_predict",
    "ctx_size",
    "top_k",
    "top_p",
    "temp",
    "repeat_penalty",
    "threads",
    "instruct",
    "interactive",
    "reverse-prompt",
    "batch_size",
    "repeat_last_n",
    "in-prefix",
    "perplexity"
    
)

# Build the command to run the main program with the configuration options
foreach ($option in $options) {
    if ($config.ContainsKey($option)) {
        Write-Verbose "Adding $option option with value $($config[$option])"
        
        # Name
        if ($option -eq "name") {
            if($modelName -eq ""){
                $modelName = "llama" # default value
            } else {
                $modelName = $($config[$option])
            }
        
        # Model
        } elseif ($option -eq "model") {
            if(($model -eq "")-or($null -eq $model)){
                $command += " --model $modelsFolder/$modelName/$modelParams/$($config[$option])"
            } else {
                $command += " --model $modelsFolder/$modelName/$modelParams/$model"
            }

        # Prompt
        } elseif ($option -eq "prompt") {
            if(($prompt -eq "")-or($prompt -eq $null)){
                $command += " --file $promptsFolder/$($config[$option]).txt"
            } else {
                $command += " --file $promptsFolder/$prompt.txt"
            }
        
        # Reverse Prompt
        } elseif ($option -eq "reverse-prompt"){
            $values = $($config[$option]) -split ","
            foreach ($value in $values) {
                $command += " --$option $value"
            }
            
        } else {
            $command += " --$option $($config[$option])"
        }
        
        
    }
}

# Run the command
Write-Host $command
try {
    Invoke-Expression $command
}
catch {
    Write-Error "An error occurred while executing the main program with the following command: $command"
}

