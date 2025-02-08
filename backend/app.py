from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import timedelta

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///app.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'super-secret-key'  # In Produktion unbedingt ersetzen!
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=1)

CORS(app)
db = SQLAlchemy(app)
jwt = JWTManager(app)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    tasks = db.relationship('Task', backref='user', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text, nullable=True)
    completed = db.Column(db.Boolean, default=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

# Anstelle von @app.before_first_request, rufen wir db.create_all() im App-Context auf
def create_tables():
    with app.app_context():
        db.create_all()

# Authentifizierungs-Routen
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({"msg": "Missing username or password"}), 400
    if User.query.filter_by(username=data['username']).first():
        return jsonify({"msg": "Username already exists"}), 400
    user = User(username=data['username'])
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()
    return jsonify({"msg": "User registered successfully"}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({"msg": "Missing username or password"}), 400
    user = User.query.filter_by(username=data['username']).first()
    if not user or not user.check_password(data['password']):
        return jsonify({"msg": "Bad username or password"}), 401
    access_token = create_access_token(identity=str(user.id))
    return jsonify(access_token=access_token), 200

# CRUD-Routen für Tasks
@app.route('/api/tasks', methods=['GET'])
@jwt_required()
def get_tasks():
    current_user_id = get_jwt_identity()
    tasks = Task.query.filter_by(user_id=current_user_id).all()
    tasks_list = [{
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'completed': task.completed
    } for task in tasks]
    return jsonify(tasks_list), 200

@app.route('/api/tasks', methods=['POST'])
@jwt_required()
def create_task():
    current_user_id = get_jwt_identity()
    data = request.get_json()
    if not data or 'title' not in data:
        return jsonify({"msg": "Missing task title"}), 400
    task = Task(
        title=data['title'],
        description=data.get('description', ''),
        completed=data.get('completed', False),
        user_id=current_user_id
    )
    db.session.add(task)
    db.session.commit()
    return jsonify({"msg": "Task created", "id": task.id}), 201

@app.route('/api/tasks/<int:task_id>', methods=['GET'])
@jwt_required()
def get_task(task_id):
    current_user_id = get_jwt_identity()
    if current_user_id is None:
        app.logger.error("No valid JWT found!")
    task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
    if not task:
        return jsonify({"msg": "Task not found"}), 404
    return jsonify({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'completed': task.completed
    }), 200

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
@jwt_required()
def update_task(task_id):
    current_user_id = get_jwt_identity()
    task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
    if not task:
        return jsonify({"msg": "Task not found"}), 404
    data = request.get_json()
    task.title = data.get('title', task.title)
    task.description = data.get('description', task.description)
    task.completed = data.get('completed', task.completed)
    db.session.commit()
    return jsonify({"msg": "Task updated"}), 200

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
@jwt_required()
def delete_task(task_id):
    current_user_id = get_jwt_identity()
    task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
    if not task:
        return jsonify({"msg": "Task not found"}), 404
    db.session.delete(task)
    db.session.commit()
    return jsonify({"msg": "Task deleted"}), 200

if __name__ == '__main__':
    create_tables()  # Tabellen erstellen, falls nicht vorhanden
    app.run(debug=True)
