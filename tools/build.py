"""Build the AVR assembly firmware with AVRA; requires Python 3."""
import argparse
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembler", default="avra", help="AVRA executable path")
    parser.add_argument("--include", type=Path, help="directory containing m16def.inc")
    args = parser.parse_args()
    executable = shutil.which(args.assembler)
    if executable is None:
        parser.error("AVRA was not found. Install it or pass --assembler PATH.")
    root = Path(__file__).resolve().parents[1]
    build = root / "build"
    build.mkdir(exist_ok=True)
    shutil.copyfile(root / "firmware/main.asm", build / "main.asm")
    command = [executable]
    if args.include:
        command += ["-I", str(args.include.resolve())]
    command += ["main.asm"]
    subprocess.run(command, cwd=build, check=True)
    print(f"Firmware: {build / 'main.hex'}")


if __name__ == "__main__":
    main()
