
import { Routes, Route, Navigate } from 'react-router-dom'
import HomePage from './pages/HomePage'
import LaunchPage from './pages/LaunchPage'
import './index.css'

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/launch" element={<LaunchPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default App
