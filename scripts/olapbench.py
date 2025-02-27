#!/usr/bin/env python3
import os
import re
import subprocess

from log import Log

log = Log()


def main():
    log.header("Install OLAPBench")
    log.info("Downloading OLAPBench")

    repo_url = "git@github.com:SQL-Storm/OLAPBench.git"
    directory = "benchmark"

    if os.path.exists(directory):
        log.info("OLAPBench exists. Pulling latest changes ...")
        subprocess.run(["git", "-C", directory, "pull", "--autostash"], check=True)
    else:
        log.info("OLAPBench does not exist. Cloning ...")
        subprocess.run(["git", "clone", repo_url, directory], check=True)

    subprocess.run("./benchmark/setup.sh", check=True)

    # Iterate through all versions
    version_pattern = re.compile(r"^v\d+\.\d+$")
    versions = [d for d in os.listdir(".") if version_pattern.match(d) and os.path.isdir(d)]

    for version in versions:
        datasets = [d for d in os.listdir(version) if os.path.isdir(os.path.join(version, d))]

        for dataset in datasets:
            if os.path.exists(os.path.join(directory, "benchmarks", dataset)):
                querysets = [d for d in os.listdir(os.path.join(version, dataset)) if os.path.isdir(os.path.join(version, dataset, d))]
                for queryset in querysets:
                    source_dir = os.path.join(version, dataset, queryset)
                    dest_dir = os.path.join(directory, "benchmarks", dataset, queryset.replace("queries", f"queries_sqlstorm_{version}"))
                    if not os.path.exists(dest_dir):
                        log.info(f"Linking `{source_dir}` to `{dest_dir}`")
                        os.symlink(os.path.abspath(source_dir), dest_dir)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.error(e)
        exit(1)
