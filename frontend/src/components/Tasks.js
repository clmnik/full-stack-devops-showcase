import React, { useEffect, useState } from 'react';
import axios from 'axios';
import TaskForm from './TaskForm';

function Tasks({ token }) {
  const [tasks, setTasks] = useState([]);
  const [error, setError] = useState('');
  const [refresh, setRefresh] = useState(false);

  const fetchTasks = () => {
    axios.get('http://127.0.0.1:5000/api/tasks', {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(response => setTasks(response.data))
    .catch(err => {
      console.error("Error fetching tasks:", err.response ? err.response.data : err);
      setError('Error fetching tasks: ' + (err.response && err.response.data.msg ? err.response.data.msg : ''));
    });
  }; // Hier den fehlenden Abschluss hinzugefügt

  useEffect(() => {
    fetchTasks();
  }, [token, refresh]);

  const handleDelete = (id) => {
    axios.delete(`http://127.0.0.1:5000/api/tasks/${id}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(() => setRefresh(!refresh))
    .catch(err => setError('Error deleting task'));
  };

  const handleToggle = (id, currentStatus) => {
    axios.put(`http://127.0.0.1:5000/api/tasks/${id}`, { completed: !currentStatus }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(() => setRefresh(!refresh))
    .catch(err => setError('Error updating task'));
  };

  return (
    <div className="container mt-5">
      <h2>Your Tasks</h2>
      {error && <div className="alert alert-danger">{error}</div>}
      <TaskForm token={token} onTaskAdded={() => setRefresh(!refresh)} />
      <ul className="list-group mt-3">
        {tasks.map(task => (
          <li key={task.id} className="list-group-item d-flex justify-content-between align-items-center">
            <div>
              <h5>{task.title}</h5>
              <p>{task.description}</p>
              <small>{task.completed ? 'Completed' : 'Pending'}</small>
            </div>
            <div>
              <button className="btn btn-sm btn-success me-2" onClick={() => handleToggle(task.id, task.completed)}>
                {task.completed ? 'Mark Incomplete' : 'Mark Complete'}
              </button>
              <button className="btn btn-sm btn-danger" onClick={() => handleDelete(task.id)}>Delete</button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default Tasks;
