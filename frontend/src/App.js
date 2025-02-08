import React, { useState } from 'react';
import { BrowserRouter as Router, Route, Switch, Redirect, Link } from 'react-router-dom';
import Login from './components/Login';
import Register from './components/Register';
import Tasks from './components/Tasks';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token') || '');

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken('');
  };

  return (
    <Router>
      <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
        <div className="container">
          <Link className="navbar-brand" to="/">DevOps Showcase</Link>
          <div className="collapse navbar-collapse">
            <ul className="navbar-nav ms-auto">
              {token ? (
                <>
                  <li className="nav-item">
                    <Link className="nav-link" to="/tasks">Tasks</Link>
                  </li>
                  <li className="nav-item">
                    <button className="btn btn-link nav-link" onClick={handleLogout}>Logout</button>
                  </li>
                </>
              ) : (
                <>
                  <li className="nav-item">
                    <Link className="nav-link" to="/login">Login</Link>
                  </li>
                  <li className="nav-item">
                    <Link className="nav-link" to="/register">Register</Link>
                  </li>
                </>
              )}
            </ul>
          </div>
        </div>
      </nav>
      <Switch>
        <Route exact path="/">
          {token ? <Redirect to="/tasks" /> : <Redirect to="/login" />}
        </Route>
        <Route path="/login">
          {token ? <Redirect to="/tasks" /> : <Login setToken={setToken} />}
        </Route>
        <Route path="/register">
          {token ? <Redirect to="/tasks" /> : <Register />}
        </Route>
        <Route path="/tasks">
          {token ? <Tasks token={token} /> : <Redirect to="/login" />}
        </Route>
      </Switch>
    </Router>
  );
}

export default App;
