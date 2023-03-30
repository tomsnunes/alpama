#!/usr/bin/env python3

"""Script to execute the "quantize" script on a given set of models."""

import argparse
import contextlib
import glob
import multiprocessing
import os
import subprocess
import sys


@contextlib.contextmanager
def create_executor(threads=1):
    if threads > 1:
        pool = multiprocessing.Pool(threads)

        def executor(func, *args):
            pool.apply_async(func, args)

    else:

        def executor(func, *args):
            return func(*args)

    try:
        yield executor
    finally:
        if threads > 1:
            pool.close()
            pool.join()


def main():
    """Update the quantize binary name depending on the platform and parse
    the command line arguments and execute the script.
    """

    if "linux" in sys.platform or "darwin" in sys.platform:
        quantize_script_binary = "quantize"

    elif "win32" in sys.platform or "cygwin" in sys.platform:
        quantize_script_binary = "quantize.exe"

    else:
        print("WARNING: Unknown platform. Assuming a UNIX-like OS.\n")
        quantize_script_binary = "quantize"

    parser = argparse.ArgumentParser(
        prog='python3 quantize.py',
        description='This script quantizes the given models by applying the '
        f'"{quantize_script_binary}" script on them.'
    )
    parser.add_argument(
        'models', nargs='+', choices=('7B', '13B', '30B', '65B'),
        help='The models to quantize.'
    )
    parser.add_argument(
        '-r', '--remove-16', action='store_true', dest='remove_f16',
        help='Remove the f16 model after quantizing it.'
    )
    parser.add_argument(
        '-m', '--models-path', dest='models_path',
        default=os.path.join(os.getcwd(), "models"),
        help='Specify the directory where the models are located.'
    )
    parser.add_argument(
        '-q', '--quantize-script-path', dest='quantize_script_path',
        default=os.path.join(os.getcwd(), quantize_script_binary),
        help='Specify the path to the "quantize" script.'
    )
    parser.add_argument(
        '-t',
        '--threads',
        dest='threads',
        type=int,
        help='Specify the number of parallel quantization tasks [default=%(default)s]',
        default=min(4, os.cpu_count()),
    )

    args = parser.parse_args()
    args.models_path = os.path.abspath(args.models_path)

    if not os.path.isfile(args.quantize_script_path):
        print(
            f'The "{quantize_script_binary}" script was not found in the '
            "current location.\nIf you want to use it from another location, "
            "set the --quantize-script-path argument from the command line."
        )
        sys.exit(1)

    with create_executor(args.threads) as executor:
        for model in args.models:
            # The model is separated in various parts
            # (ggml-model-f16.bin, ggml-model-f16.bin.0, ggml-model-f16.bin.1...)
            f16_model_path_base = os.path.join(
                args.models_path, model, "ggml-model-f16.bin"
            )

            if not os.path.isfile(f16_model_path_base):
                print(f'The file %s was not found' % f16_model_path_base)
                sys.exit(1)

            f16_model_parts_paths = map(
                lambda filename: os.path.join(f16_model_path_base, filename),
                glob.glob(f"{f16_model_path_base}*"),
            )

            for f16_model_part_path in f16_model_parts_paths:
                if not os.path.isfile(f16_model_part_path):
                    print(
                        f"The f16 model {os.path.basename(f16_model_part_path)} "
                        f"was not found in {args.models_path}{os.path.sep}{model}"
                        ". If you want to use it from another location, set the "
                        "--models-path argument from the command line."
                    )
                    sys.exit(1)

                executor(
                    __run_quantize_script,
                    args.quantize_script_path,
                    f16_model_part_path,
                    args.remove_f16,
                )


def __run_quantize_script(script_path, f16_model_part_path, remove_f16):
    """Run the quantize script specifying the path to it and the path to the
    f16 model to quantize.
    """

    new_quantized_model_path = f16_model_part_path.replace("f16", "q4_0")
    subprocess.run(
        [script_path, f16_model_part_path, new_quantized_model_path, "2"],
        check=True
    )
    if remove_f16:
        os.remove(f16_model_part_path)


if __name__ == "__main__":
    try:
        main()

    except subprocess.CalledProcessError:
        print("\nAn error ocurred while trying to quantize the models.")
        sys.exit(1)

    except KeyboardInterrupt:
        sys.exit(0)

    else:
        print("\nSuccesfully quantized all models.")
