import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import Landing from './pages/Landing';
import Login from './pages/Login';
import Signup from './pages/Signup';
import ForgotPassword from './pages/ForgotPassword';
import Home from './pages/Home';
import Profile from './pages/Profile';
import ShortestRoute from './pages/ShortestRoute';
import MyTickets from './pages/MyTickets';
import FileComplaint from './pages/FileComplaint';
import SafetyMonitor from './pages/SafetyMonitor';

const AnimatedRoutes = () => {
    const location = useLocation();

    return (
        <AnimatePresence mode="wait">
            <Routes location={location} key={location.pathname}>
                <Route path="/" element={<Landing />} />
                <Route path="/login" element={<Login />} />
                <Route path="/signup" element={<Signup />} />
                <Route path="/forgot-password" element={<ForgotPassword />} />
                <Route path="/home" element={<Home />} />
                <Route path="/profile" element={<Profile />} />
                <Route path="/shortest-route" element={<ShortestRoute />} />
                <Route path="/my-tickets" element={<MyTickets />} />
                <Route path="/file-complaint" element={<FileComplaint />} />
                <Route path="/safety-monitor" element={<SafetyMonitor />} />
            </Routes>
        </AnimatePresence>
    );
};

function App() {
    return (
        <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
            <div className="min-h-screen font-sans selection:bg-primary selection:text-dark">
                <AnimatedRoutes />
            </div>
        </Router>
    );
}

export default App;
