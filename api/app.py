from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import os
import time

app = Flask(__name__)
CORS(app)

def get_db():
    retries = 5
    while retries > 0:
        try:
            return mysql.connector.connect(
                host=os.environ.get("DB_HOST", "db"),
                user=os.environ.get("DB_USER", "root"),
                password=os.environ.get("DB_PASSWORD", "rootpass"),
                database=os.environ.get("DB_NAME", "coffeeshop")
            )
        except mysql.connector.Error:
            retries -= 1
            time.sleep(5)
    return None

@app.route("/api/health")
def health():
    return jsonify({"status": "ok"})

@app.route("/api/reservations", methods=["GET"])
def get_reservations():
    db = get_db()
    if not db:
        return jsonify({"error": "Database not available"}), 500
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM reservations ORDER BY date, time")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    for r in results:
        r["date"] = str(r["date"])
        r["time"] = str(r["time"])
        r["created_at"] = str(r["created_at"])
    return jsonify(results)

@app.route("/api/reservations", methods=["POST"])
def create_reservation():
    data = request.json
    required = ["name", "email", "date", "time", "guests"]
    for field in required:
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400
    db = get_db()
    if not db:
        return jsonify({"error": "Database not available"}), 500
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO reservations (name, email, phone, date, time, guests, message) VALUES (%s, %s, %s, %s, %s, %s, %s)",
        (data["name"], data["email"], data.get("phone", ""), data["date"], data["time"], data["guests"], data.get("message", ""))
    )
    db.commit()
    new_id = cursor.lastrowid
    cursor.close()
    db.close()
    return jsonify({"message": "Reservation created", "id": new_id}), 201

@app.route("/api/reservations/<int:id>", methods=["DELETE"])
def delete_reservation(id):
    db = get_db()
    if not db:
        return jsonify({"error": "Database not available"}), 500
    cursor = db.cursor()
    cursor.execute("DELETE FROM reservations WHERE id = %s", (id,))
    db.commit()
    deleted = cursor.rowcount
    cursor.close()
    db.close()
    if deleted:
        return jsonify({"message": "Reservation deleted"})
    return jsonify({"error": "Not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)