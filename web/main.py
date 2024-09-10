from flask import Flask, request, jsonify, send_from_directory
from fitparse import FitFile
from flask_cors import CORS
from os.path import join
from itertools import groupby
from operator import itemgetter

app = Flask(__name__, static_folder='dist')
CORS(app)

@app.route('/')
def index(): return send_from_directory(app.static_folder, 'index.html')

@app.route('/assets/<path:filename>')
def serve_assets(filename): return send_from_directory(join('dist', 'assets'), filename)

@app.route('/fit2json', methods=['POST'])
def fit2json():
    if 'file' not in request.files: return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '': return jsonify({'error': 'No selected file'}), 400
    if file and file.filename.lower().endswith('.fit'):
        try:
            fit_file = FitFile(file)
            mapped_messages = [(msg.name, msg.get_values()) for msg in fit_file.get_messages()]
            grouped_messages = {k: [v for _, v in g] for k, g in groupby(sorted(mapped_messages, key=itemgetter(0)), key=itemgetter(0))}
            return jsonify(grouped_messages)
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    return jsonify({'error': 'Invalid file format'}), 400

@app.route('/tcx2json', methods=['POST'])
def tcx2json():
    if 'file' not in request.files: return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '': return jsonify({'error': 'No selected file'}), 400
    if file and file.filename.lower().endswith('.tcx'):
        try:
            tcx_file = file.read().decode('utf-8')
            return jsonify({'tcx': tcx_file})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    return jsonify({'error': 'Invalid file format'}), 400

@app.route('/gpx2json', methods=['POST'])
def gpx2json():
    if 'file' not in request.files: return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '': return jsonify({'error': 'No selected file'}), 400
    if file and file.filename.lower().endswith('.gpx'):
        try:
            gpx_file = file.read().decode('utf-8')
            return jsonify({'gpx': gpx_file})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    return jsonify({'error': 'Invalid file format'}), 400

if __name__ == '__main__': app.run(debug=True, port=8513)