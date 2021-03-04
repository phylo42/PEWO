
import click
import os

def remove_empty(input_files):
    """
    Removes empty files. Needed for debuggig purposes.
    """
    for f in input_files:
        if os.stat(f).st_size == 0:
            print("Removing", f, "...")
            os.remove(f)


@click.command()
@click.argument('input_files', type=click.Path(exists=True), nargs=-1)
def cli(input_files):
    if len(input_files) == 0:
        print("No input files provided.")
    else:
        remove_empty(input_files)
	

if __name__ == "__main__":
    cli()
