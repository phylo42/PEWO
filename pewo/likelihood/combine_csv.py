import click
import likelihood


@click.command()
@click.option('-o', '--output-file', type=click.Path(exists=False), required=True)
@click.argument('input_files', type=click.Path(exists=True), nargs=-1)
def run(output_file, input_files):
    if len(input_files) == 0:
        print("No input files provided.")
    else:
        likelihood.combine_csv(input_files, output_file)
	

if __name__ == "__main__":
    run()
