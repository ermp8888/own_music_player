from flask import Flask, request, jsonify, send_from_directory
import yt_dlp
import os
import uuid

app = Flask(__name__)

# Route to download/extract audio
@app.route('/download', methods=['POST'])
def download():
    url = request.json.get('url')
    if not url:
        return jsonify({'error': 'URL is required'}), 400
        
    output_id = str(uuid.uuid4())
    tmp_dir = '/tmp'
    if not os.path.exists(tmp_dir):
        os.makedirs(tmp_dir)
        
    ydl_opts = {
        'format': 'bestaudio',
        'audio-quality': '0',
        'outtmpl': f'{tmp_dir}/{output_id}.%(ext)s',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
        }],
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        # Return filename so the app can fetch it via /files/<filename>
        return jsonify({'file': f'{output_id}.mp3'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Route to serve the downloaded files
@app.route('/files/<filename>', methods=['GET'])
def get_file(filename):
    return send_from_directory('/tmp', filename, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
