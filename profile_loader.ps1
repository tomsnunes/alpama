
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
    $reversePrompt,

    [Parameter()]
    [string]
    [ValidateSet('alpaca','chat-with-bob', 'dan', 'chatdoctor', 'reason-act', 'chat-13b','vicuna')]
    $promptFile,

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
$modelsFolder   =  "./models"
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
    "interactive",          # run in interactive mode
    "interactive-first",    # run in interactive mode and wait for input right away
    "instruct",             # run in instruction mode (use with Alpaca models)
    "reverse-prompt",       # run in interactive mode and poll user input upon seeing PROMPT (can be specified more than once for multiple prompts).
    "color",                # colorise output to distinguish prompt and user input from generations
    "seed",                 # RNG seed (default: -1, use random seed for <= 0)
    "threads",              # number of threads to use during computation (default: 4)
    "prompt",               # prompt to start generation with (default: empty)
    "random-prompt",        # start with a randomized prompt.
    "in-prefix",            # string to prefix user inputs with (default: empty)
    "file",                 # prompt file to start generation.
    "n_predict",            # number of tokens to predict (default: 128, -1 = infinity)
    "top_k",                # top-k sampling (default: 40)
    "top_p",                # top-p sampling (default: 0.9)
    "repeat_last_n",        # last n tokens to consider for penalize (default: 64)
    "repeat_penalty",       # penalize repeat sequence of tokens (default: 1.1)
    "ctx_size",             # size of the prompt context (default: 512)
    "ignore-eos",           # ignore end of stream token and continue generating
    "memory_f32",           # use f32 instead of f16 for memory key+value
    "temp",                 # temperature (default: 0.8)
    "n_parts",              # number of model parts (default: -1 = determine from dimensions)
    "batch_size",           # batch size for prompt processing (default: 8)
    "perplexity",           # compute perplexity over the prompt
    "keep",                 # number of tokens to keep from the initial prompt (default: 0, -1 = all)
    "mlock",                # force system to keep model in RAM rather than swapping or compressing
    "no-nmap",              # do not memory-map model (slower load but may reduce pageouts if not using mlock)
    "mtest",                # compute maximum memory usage
    "verbose-prompt",       # print prompt before generation
    "model"                 # model path (default: models/lamma-7B/ggml-model.bin)
)

# Build the command to run the main program with the configuration options
foreach ($option in $options) {
    if ($config.ContainsKey($option)) {
        Write-Verbose "Adding $option option with value $($config[$option])"

        # Check for default values
        $defaultValue = $null
        switch ($option) {
            "model" {
                $defaultValue = "$modelsFolder/$profileName/$modelParams/$modelName"
                break
            }
            "file" {
                $defaultValue = "$promptsFolder/$promptFile.txt"
                break      
            }
            # Add cases for other options with default values here
        }

        # Use default value if the configuration value is empty or null
        if ([string]::IsNullOrEmpty($config[$option])) {
            $command += " --$option $defaultValue"
        }

        # Use the configuration value if it exists
        else {
            switch ($option) {
                "model" {
                    if ($PSBoundParameters.ContainsKey('modelName')) {
                        $command += " --$option $modelsFolder/$profileName/$modelParams/$modelName"
                        break
                    } else {
                        $command += " --$option $modelsFolder/$profileName/$modelParams/$($config[$option])"
                    }
                }
                "file" {
                    if ($PSBoundParameters.ContainsKey('promptFile')) {
                        $command += " --file $promptsFolder/$promptFile.txt"
                        break
                    } else {
                        $command += " --file $promptsFolder/$($config[$option]).txt"
                    }
                }
                "reverse-prompt" {
                    if ($PSBoundParameters.ContainsKey('reversePrompt')) {
                        $values = $reversePrompt -split ","
                        foreach ($value in $values) {
                            $command += " --$option $value"
                        } 
                        break
                    }
                }
                Default {
                    $command += " --$option $($config[$option])"
                }
            }
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

