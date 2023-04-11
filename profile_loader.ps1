# This PowerShell script is designed to provide a user-friendly interface for loading configuration profiles without using Python on Windows environments. It acts as a wrapper to load the possible parameters of the llama.cpp binary, which is a language model for generating text.
# The script takes several parameters that allow the user to customize the behavior of the llama.cpp binary. The parameters include:
#     $modelName: A string parameter that specifies the name of the model to load. It has a default value of "llama" and accepts a predefined set of values for different models, such as "alpaca", "gpt-2", "vicuna", etc.
#     $modelParams: A string parameter that specifies the parameters of the model to load. It has a default value of "7b" and accepts a predefined set of values for different parameter configurations, such as "7b", "30b", etc.
#     $profileName: A string parameter that specifies the name of the configuration profile to load. It has a default value of the $modelName parameter, but can be overridden with a custom value.
#     $reversePrompt: A string parameter that specifies a reverse prompt to use during text generation. It can be used multiple times to specify multiple reverse prompts.
#     $promptFile: A string parameter that specifies a file containing prompts to use during text generation. It accepts a predefined set of values for different prompt files, such as "alpaca", "chat-with-bob", etc.
#     $perplexity: A boolean parameter that indicates whether to compute perplexity over the prompts. It has a default value of false.
#
# The script also defines default paths for various files and folders related to the llama.cpp binary, such as the binary path, models folder, profiles folder, prompts folder, and datasets folder. It then attempts to read the configuration file specified by the $profileName parameter as a hash table, storing the key-value pairs in a $config variable.
# The script also defines a set of configuration options for the llama.cpp binary as an array of strings. These options include various parameters for controlling the behavior of the text generation process, such as temperature, top-k sampling, batch size, and more.
# Finally, the script builds the command to run the llama.cpp binary with the specified configuration options based on the values of the parameters and the loaded configuration file. The command is then executed, allowing the user to generate text using the llama.cpp binary with the desired configuration. The script also includes error handling for reading the configuration file and provides verbose output for debugging purposes.
# The benefits of using this PowerShell script as a wrapper for loading configuration profiles for the llama.cpp binary without using Python on Windows environments include:

#   User-friendly interface: The script provides a clear and descriptive help message for each command line argument, making it easy for users to understand how to use the script and specify the desired configuration options.
#   Flexibility: By using command line arguments, users can easily customize the behavior of the llama.cpp binary by specifying different values for model name, model parameters, profile name, reverse prompt, prompt file, and other options. This allows for greater flexibility and adaptability of the script to different use cases.
#   Error handling: The script includes error handling to catch and handle exceptions that may occur while reading the configuration file. This helps to provide informative error messages to users in case of any issues, making it easier to diagnose and fix problems.
#   Reusability: The script can be easily reused in different projects or scenarios where the llama.cpp binary is used with different configuration profiles. This makes it a handy tool for loading configuration profiles in a user-friendly way, without having to manually specify all the options every time.
#   Maintainability: The script uses a modular and organized approach, separating the command line argument parsing, configuration file reading, and command building into different sections. This makes the script easier to understand, update, and maintain in the future.
#   Debug: The script provides verbose output for debugging purposes, allowing users to easily identify and fix any issues that may arise during the execution of the script. This helps to streamline the troubleshooting process and ensures that users can quickly resolve any problems.

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
    [ValidateSet('alpaca','chat-with-bob', 'dan', 'chatdoctor', 'reason-act', 'chat-13b','vicuna', 'cabrita')]
    $promptFile,

    [Parameter()]
    [bool]
    $perplexity=$false,

    [Parameter()]
    [string]
    $loraAdapter
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
$lorasFolder = "./loras"
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
    "lora",                 # apply LoRA adapter (implies --no-mmap)
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
                        $command += " --$option $modelsFolder/$profileName/$modelParams/$modelName.bin"
                        break
                    } else {
                        $command += " --$option $modelsFolder/$profileName/$modelParams/$($config[$option])"
                    }
                }
                "lora" {
                    if ($PSBoundParameters.ContainsKey('loraAdapter')) {
                        $command += " --$option $lorasFolder/$loraAdapter"
                        break
                    } else {
                        $command += " --$option $lorasFolder/$($config[$option])"
                    }
                }
                "file" {
                    if ($PSBoundParameters.ContainsKey('promptFile')) {
                        $command += " --file $promptsFolder/$promptFile.txt"
                        break
                    } else {
                        $command += " --file $promptsFolder/$($config[$option])"
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

