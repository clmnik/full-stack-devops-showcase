import React, { useState } from 'react';
import axios from 'axios';

function TaskForm({ token, onTaskAdded }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    axios.post('http://127.0.0.1:5000/api/tasks', { title, description }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(() => {
      setTitle('');
      setDescription('');
      onTaskAdded();
    })
    .catch(err => console.error("Error adding task:", err));
  };

  return (
    <form onSubmit={handleSubmit} className="mb-3">
      <div className="mb-3">
        <input
          type="text"
          className="form-control"
          placeholder="Task title"
          value={title}
          onChange={e => setTitle(e.target.value)}
          required
        />
      </div>
      <div className="mb-3">
        <textarea
          className="form-control"
          placeholder="Task description"
          value={description}
          onChange={e => setDescription(e.target.value)}
        />
      </div>
      <button type="submit" className="btn btn-primary">Add Task</button>
    </form>
  );
}

export default TaskForm;
