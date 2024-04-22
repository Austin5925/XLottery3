import React from 'react';
import './Popup.css';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import KOLPage from './KOLPage';
import UserPage from './UserPage';

function Popup() {
  return (
    <Router>
      <div className="App">
        <nav>
          <ul>
            <li>
              <Link to="/kol">我是KOL</Link>
            </li>
            <li>
              <Link to="/user">我是用户</Link>
            </li>
          </ul>
        </nav>
        <div style={{ paddingTop: '50px' }}>
          <Routes>
            <Route path="/kol" element={<KOLPage />} />
            <Route path="/user" element={<UserPage />} />
            <Route path="/" element={<KOLPage />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default Popup;
