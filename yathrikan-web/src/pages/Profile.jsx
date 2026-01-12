import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { User, Settings, Bell, HelpCircle, LogOut, ArrowLeft, ChevronRight } from 'lucide-react';
import Button from '../components/ui/Button';
import { useAuth } from '../contexts/AuthContext';

const Profile = () => {
    const navigate = useNavigate();
    const { logout, user } = useAuth();

    const menuItems = [
        { icon: <User />, label: 'Edit Profile', path: '/edit-profile' },
        { icon: <Bell />, label: 'Notifications', path: '/notifications' },
        { icon: <Settings />, label: 'Settings', path: '/settings' },
        { icon: <HelpCircle />, label: 'Help & Support', path: '/help' },
    ];

    const handleLogout = async () => {
        if (window.confirm('Are you sure you want to logout?')) {
            try {
                await logout();
                navigate('/');
            } catch (error) {
                alert('Failed to logout');
            }
        }
    };

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen bg-slate-50 pb-24 lg:pb-0"
        >
            {/* Header */}
            <header className="bg-primary p-6 rounded-b-[40px] shadow-lg relative">
                <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => navigate('/home')}
                    className="absolute top-6 left-6 p-3 bg-white/30 backdrop-blur-md rounded-full text-dark"
                >
                    <ArrowLeft size={24} />
                </motion.button>
                <h1 className="text-2xl font-black text-dark text-center">Profile</h1>
            </header>

            {/* Profile Card */}
            <div className="p-6 max-w-2xl mx-auto">
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    className="bg-white rounded-[32px] p-8 shadow-lg mb-6"
                >
                    <div className="flex items-center gap-6">
                        <div className="w-24 h-24 bg-dark rounded-full overflow-hidden border-4 border-primary shadow-xl">
                            <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(user?.displayName || user?.email || 'User')}&background=0F172A&color=FACC15&size=200`} alt="Profile" />
                        </div>
                        <div className="flex-1">
                            <h2 className="text-2xl font-black text-dark">{user?.displayName || 'User'}</h2>
                            <p className="text-slate-500 font-medium">{user?.email}</p>
                        </div>
                    </div>
                </motion.div>

                {/* Menu Items */}
                <div className="space-y-3">
                    {menuItems.map((item, index) => (
                        <motion.button
                            key={index}
                            initial={{ x: -20, opacity: 0 }}
                            animate={{ x: 0, opacity: 1 }}
                            transition={{ delay: index * 0.1 }}
                            whileHover={{ x: 5 }}
                            whileTap={{ scale: 0.98 }}
                            onClick={() => navigate(item.path)}
                            className="w-full bg-white rounded-[24px] p-6 shadow-sm flex items-center gap-4 group hover:shadow-md transition-all"
                        >
                            <div className="p-3 bg-slate-100 rounded-2xl text-dark group-hover:bg-primary group-hover:text-dark transition-colors">
                                {item.icon}
                            </div>
                            <span className="flex-1 text-left font-bold text-dark">{item.label}</span>
                            <ChevronRight className="text-slate-400 group-hover:text-dark transition-colors" />
                        </motion.button>
                    ))}
                </div>

                {/* Logout Button */}
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.5 }}
                    className="mt-8"
                >
                    <Button
                        onClick={handleLogout}
                        variant="outline"
                        className="w-full py-5 text-lg border-2 border-red-200 text-red-600 hover:bg-red-50 flex items-center justify-center gap-2"
                    >
                        <LogOut size={20} />
                        Logout
                    </Button>
                </motion.div>
            </div>
        </motion.div>
    );
};

export default Profile;
