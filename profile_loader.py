#
# This Python script is designed to provide a user-friendly interface for loading configuration profiles to be used with the llama.cpp binary. The script uses the argparse library to parse command line arguments and provides a help description for each argument.
# The available command line arguments are:
#   -modelName: The name of the model to use, with options including llama, alpaca, alpaca-lora, gpt-2, gpt4all, chatdoctor, vicuna, point-alpaca, and gpt4-x-alpaca-native.
#   -modelParams: The parameters of the model to use, with options including 7b, 13b, 30b, 65b, and 117m.
#   -profileName: The name of the profile to load.
#   -reversePrompt: The reverse prompt to use.
#   -promptFile: The prompt file to use, with options including alpaca, chat-with-bob, dan, chatdoctor, reason-act, chat-13b, and vicuna.
#   -perplexity: A flag to indicate whether to compute perplexity over the prompt.
#
# The script also defines default paths for various folders, such as models, profiles, prompts, and datasets. It then constructs the command to run the main program based on the specified options and loads the configuration file as a dictionary. The script also defines a list of available configuration file options, which can be used to customize the behavior of the llama.cpp binary.
# The benefits of this approach include:
#   User-friendly interface: The script provides a clear and descriptive help message for each command line argument, making it easy for users to understand how to use the script and specify the desired configuration options.
#   Flexibility: By using command line arguments, users can easily customize the behavior of the llama.cpp binary by specifying different values for model name, model parameters, profile name, reverse prompt, prompt file, and other options. This allows for greater flexibility and adaptability of the script to different use cases.
#   Error handling: The script includes error handling to catch and handle exceptions that may occur while reading the configuration file. This helps to provide informative error messages to users in case of any issues, making it easier to diagnose and fix problems.
#   Reusability: The script can be easily reused in different projects or scenarios where the llama.cpp binary is used with different configuration profiles. This makes it a handy tool for loading configuration profiles in a user-friendly way, without having to manually specify all the options every time.
#   Maintainability: The script uses a modular and organized approach, separating the command line argument parsing, configuration file reading, and command building into different sections. This makes the script easier to understand, update, and maintain in the future.
#   Debug: The script provides verbose output for debugging purposes, allowing users to easily identify and fix any issues that may arise during the execution of the script. This helps to streamline the troubleshooting process and ensures that users can quickly resolve any problems.

import argparse
import subprocess
import os

parser = argparse.ArgumentParser(description="Description of your script")
parser.add_argument('-modelName', type=str, default='', choices=['alpaca','alpaca-lora','chatdoctor','codegen''gpt-2','gpt4-x-alpaca-native','gpt4all','llama','point-alpaca','vicuna'], help="Model name")
parser.add_argument('-modelParams', type=str, default='7b', choices=['117m','2b','6b','7b','13b','30b','65b'], help="Model parameters")
parser.add_argument('-profileName', type=str, default='llama', help="Profile name")
parser.add_argument('-reversePrompt', type=str, help="Reverse prompt")
parser.add_argument('-promptFile', type=str, choices=['alpaca','cabrita','chat-13b','chat-with-bob','chatdoctor','codegen','dan','reason-act','vicuna'], help="Prompt")
parser.add_argument('-perplexity', action='store_true', help="Perplexity flag")
parser.add_argument('-loraAdapter', type=str, default='', help="Lora adapter name")

args = parser.parse_args()

# Build definitions
build_variant = "Release"  # Debug | Release
build_target_folder = "./bin"

binary_path = os.path.join(build_target_folder, build_variant)

# llama.cpp binaries
main_binary = "main.exe"
perplexity_binary = "perplexity.exe"

# Set default paths
models_folder   = "./models"
loras_folder    = "./loras"
profiles_folder = "./profiles"
prompts_folder  = "./prompts"
datasets_folder = "./datasets"

# Perplexity
dataset = "wikitext-2-raw"
perplexity_test = "wiki.test.raw"

# Loads the proper binary for the operation
if args.perplexity:
    profileName = "perplexity_{args.modelName}"
    command = os.path.join(binary_path,perplexity_binary)
    command += f" --file {os.path.join(datasets_folder,dataset,perplexity_test)}"
else:
    command = os.path.join(binary_path,main_binary)

# Load the configuration file as a dictionary
try:
    config = {}
    with open(f"{os.path.join(profiles_folder,args.profileName)}.ini") as f:
        for line in f:
            # Skip comments and empty lines
            if not line.strip().startswith("#") and not line.strip().startswith(";") and line.strip():
                key, value = line.strip().split("=", 1)
                config[key.strip()] = value.strip()
except Exception as e:
    print(f"An error occurred while reading the configuration file: {e}")
    # Handle the error here

print(f"DEBUG: Initial config: {config}")

# Define the configuration file options
options = [
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
]

# Build the command to run the main program with the configuration options
for option in options:
    if option in config:
        print("Adding", option, "option with value", config[option])

        # Check for default values
        default_value = '' # ?
        if option == "model":
            default_value = os.path.join(models_folder,args.profileName,args.modelParams,config[option])
        elif option == "file":
            default_value = f"{os.path.join(prompts_folder,config[option])}.txt"
        # Add cases for other options with default values here


        # Use default value if the configuration value is empty or None
        if config[option] is None or config[option] == "":
            command += f" --{option} {default_value}"


        # Use the configuration value if it exists
        else:
            if option == "model":
                if (args.modelName):
                    command += f" --{option} {os.path.join(models_folder,args.profileName,args.modelParams,args.modelName)}.bin"
                else:
                    command += f" --{option} {os.path.join(models_folder,args.profileName,args.modelParams,config[option])}"
            elif option == "lora":
                if (args.loraAdapter):
                    command += f" --{option} {os.path.join(loras_folder, args.loraAdapter)}"
                else:
                    command += f" --{option} {os.path.join(loras_folder,config[option])}"
            elif option == "file":
                if (args.promptFile):
                    command += f" --file {os.path.join(prompts_folder, args.promptFile)}.txt"
                else:
                    command += f" --file {os.path.join(prompts_folder, config[option])}"
            elif option == "reverse-prompt":
                if (args.reversePrompt):
                    values = config[option].split(",")
                    for value in values:
                        command += f" --{option} {value}"
            else:
                command += f" --{option} {config[option]}"

# Run the command
print(command)
try:
    subprocess.run(command, shell=False, check=True)
except subprocess.CalledProcessError as e:
    print(f"An error occurred while executing the main program with the following command: {command}")
    print(e)