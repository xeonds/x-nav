import argparse
import json
from fitparse import FitFile
from itertools import groupby
from operator import itemgetter
from datetime import datetime

def default_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()
    raise TypeError(f'Object of type {o.__class__.__name__} is not JSON serializable')

def fit2json(file):
    if file and file.lower().endswith('.fit'):
        try:
            fit_file = FitFile(file)
            mapped_messages = [(msg.name, msg.get_values()) for msg in fit_file.get_messages()]
            grouped_messages = {k: [v for _, v in g] for k, g in groupby(sorted(mapped_messages, key=itemgetter(0)), key=itemgetter(0))}
            return grouped_messages
        except Exception as e:
            return {'error': str(e)}, 500
    return {'error': 'Invalid file format'}, 400

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert FIT file to JSON.')
    parser.add_argument('input_file', help='Path to the input FIT file')
    parser.add_argument('-o', '--output', help='Path to the output JSON file (optional)')
    args = parser.parse_args()

    try:
        result = fit2json(args.input_file)
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(result, f, indent=4, default=default_converter)
        else:
            print(json.dumps(result, indent=4, default=default_converter))
    except Exception as e:
        print(json.dumps({'error': str(e)}, indent=4, default=default_converter))
