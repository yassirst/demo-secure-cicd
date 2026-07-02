from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    """Basic endpoint just so the pipeline has something to build/test/scan."""
    return jsonify({"message": "Hello, secure CI/CD!"}), 200


@app.route("/health")
def health():
    """Used by the Dockerfile HEALTHCHECK."""
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
