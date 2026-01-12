import { motion } from 'framer-motion';
import {
    Bell,
    Map as MapIcon,
    User,
    Route,
    Ticket,
    ShieldCheck,
    AlertCircle,
    Navigation,
    Compass,
    ArrowRight
} from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const Home = () => {
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = useState('home');

    const stats = [
        { label: 'Next Bus Arriving', value: '8', unit: 'min', color: 'bg-primary' },
        { label: 'Current Speed', value: '42', unit: 'km/h', color: 'bg-slate-100' },
    ];

    const actions = [
        { name: 'Shortest Route', icon: <Route />, color: 'bg-slate-900', textColor: 'text-primary', path: '/shortest-route' },
        { name: 'My Tickets', icon: <Ticket />, color: 'bg-primary', textColor: 'text-slate-900', path: '/my-tickets' },
        { name: 'File Complaint', icon: <AlertCircle />, color: 'bg-slate-100', textColor: 'text-slate-900', path: '/file-complaint' },
        { name: 'Safety Monitor', icon: <ShieldCheck />, color: 'bg-slate-900', textColor: 'text-primary', path: '/safety-monitor' },
    ];

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen bg-slate-50 pb-24 lg:pb-0 lg:pl-24"
        >
            {/* Mobile Header */}
            <header className="bg-primary p-6 rounded-b-[40px] shadow-lg flex justify-between items-center lg:rounded-none lg:shadow-none lg:bg-white lg:border-b lg:sticky lg:top-0 lg:z-10">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-dark rounded-full overflow-hidden border-2 border-white shadow-md">
                        <img src="https://ui-avatars.com/api/?name=Albin+Thomas&background=0F172A&color=FACC15" alt="Profile" />
                    </div>
                    <div>
                        <h2 className="text-sm font-bold text-dark/60 uppercase tracking-widest leading-none">Welcome back,</h2>
                        <h1 className="text-xl font-black text-dark">Albin Thomas</h1>
                    </div>
                </div>
                <button onClick={() => alert('🔔 No notifications yet!')} className="p-3 bg-white/30 backdrop-blur-md rounded-2xl relative">
                    <Bell size={24} className="text-dark" />
                    <span className="absolute top-2 right-2 w-3 h-3 bg-red-500 border-2 border-primary rounded-full" />
                </button>
            </header>

            {/* Main Content Area */}
            <main className="p-6 space-y-8 max-w-6xl mx-auto">

                {/* Map Section Redesign */}
                <section className="relative group">
                    <div className="h-72 w-full bg-slate-200 rounded-[32px] overflow-hidden shadow-2xl relative border-4 border-white">
                        {/* Mock Map Background */}
                        <div className="absolute inset-0 bg-[url('https://api.mapbox.com/styles/v1/mapbox/light-v10/static/76.2711,10.8505,14,0/800x400?access_token=pk.mock')] bg-cover bg-center" />

                        {/* Map Overlay Elements */}
                        <div className="absolute inset-0 bg-dark/5" />

                        <motion.div
                            animate={{ scale: [1, 1.2, 1], opacity: [0.5, 0.8, 0.5] }}
                            transition={{ repeat: Infinity, duration: 4 }}
                            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-32 h-32 bg-primary/20 rounded-full blur-2xl"
                        />

                        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 p-2 bg-white rounded-full shadow-xl">
                            <div className="w-4 h-4 bg-blue-500 rounded-full animate-pulse" />
                        </div>

                        {/* Recenter Button */}
                        <button className="absolute bottom-6 right-6 p-4 bg-white rounded-2xl shadow-xl active:scale-95 transition-transform">
                            <Compass className="text-dark" />
                        </button>

                        {/* Floating Info Tag */}
                        <div className="absolute top-6 left-6 flex items-center gap-2 px-4 py-2 bg-white/90 backdrop-blur rounded-full shadow-lg border border-white">
                            <span className="w-2 h-2 bg-green-500 rounded-full" />
                            <span className="text-xs font-black uppercase text-dark">Live Location Active</span>
                        </div>
                    </div>
                </section>

                {/* Stats Row */}
                <div className="grid grid-cols-2 gap-4">
                    {stats.map((stat, i) => (
                        <motion.div
                            key={i}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            transition={{ delay: i * 0.1 }}
                            className={`${stat.color} p-6 rounded-[32px] shadow-sm relative overflow-hidden`}
                        >
                            <p className="text-xs font-bold uppercase opacity-60 mb-2">{stat.label}</p>
                            <div className="flex items-baseline gap-1">
                                <span className="text-4xl font-black">{stat.value}</span>
                                <span className="text-sm font-bold opacity-70">{stat.unit}</span>
                            </div>
                            <div className="absolute -bottom-2 -right-2 opacity-5">
                                {i === 0 ? <Navigation size={80} /> : <Compass size={80} />}
                            </div>
                        </motion.div>
                    ))}
                </div>

                {/* Quick Actions Grid */}
                <section className="space-y-4">
                    <div className="flex justify-between items-end">
                        <h3 className="text-2xl font-black text-dark">Quick Actions</h3>
                        <button className="text-sm font-bold text-primary-dark opacity-40 hover:opacity-100 transition-opacity">VIEW ALL</button>
                    </div>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        {actions.map((action, i) => (
                            <motion.button
                                key={i}
                                whileHover={{ y: -5 }}
                                whileTap={{ scale: 0.95 }}
                                onClick={() => navigate(action.path)}
                                className={`${action.color} p-6 rounded-[32px] flex flex-col justify-between h-40 text-left shadow-xl group`}
                            >
                                <div className={`p-3 rounded-2xl w-fit ${action.color === 'bg-slate-100' ? 'bg-white' : 'bg-white/10'}`}>
                                    <div className={action.textColor}>{action.icon}</div>
                                </div>
                                <div className="flex items-center justify-between">
                                    <span className={`font-black text-sm uppercase leading-tight ${action.textColor}`}>
                                        {action.name.split(' ').map((word, j) => (
                                            <span key={j} className="block">{word}</span>
                                        ))}
                                    </span>
                                    <ArrowRight size={16} className={`${action.textColor} opacity-0 group-hover:opacity-100 transition-opacity`} />
                                </div>
                            </motion.button>
                        ))}
                    </div>
                </section>

            </main>

            {/* Modern Tab Bar (Mobile) */}
            <nav className="fixed bottom-0 left-0 right-0 p-4 lg:hidden">
                <div className="bg-dark/95 backdrop-blur-xl rounded-[32px] p-2 flex justify-between items-center shadow-2xl border border-white/5">
                    {[
                        { id: 'home', icon: <MapIcon />, label: 'Discover' },
                        { id: 'route', icon: <Route />, label: 'Planner' },
                        { id: 'profile', icon: <User />, label: 'Profile' }
                    ].map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => {
                                if (tab.id === 'profile') {
                                    navigate('/profile');
                                } else {
                                    setActiveTab(tab.id);
                                }
                            }}
                            className={`flex-1 flex flex-col items-center py-4 rounded-2xl transition-all relative ${activeTab === tab.id ? 'text-primary' : 'text-slate-400'
                                }`}
                        >
                            {tab.icon}
                            {activeTab === tab.id && (
                                <motion.span
                                    layoutId="nav_bubble"
                                    className="absolute inset-0 bg-white/5 rounded-2xl -z-10"
                                />
                            )}
                        </button>
                    ))}
                </div>
            </nav>

            {/* Sidebar (Desktop) */}
            <nav className="hidden lg:flex fixed left-0 top-0 bottom-0 w-24 bg-dark flex-col items-center py-10 gap-10">
                <BusIcon className="text-primary w-10 h-10" />
                <div className="flex-1 flex flex-col gap-8">
                    <SidebarIcon icon={<MapIcon />} active={activeTab === 'home'} onClick={() => setActiveTab('home')} />
                    <SidebarIcon icon={<Route />} onClick={() => navigate('/shortest-route')} />
                    <SidebarIcon icon={<Ticket />} onClick={() => navigate('/my-tickets')} />
                    <SidebarIcon icon={<ShieldCheck />} onClick={() => navigate('/safety-monitor')} />
                </div>
                <SidebarIcon icon={<User />} active={activeTab === 'profile'} onClick={() => navigate('/profile')} />
            </nav>
        </motion.div>
    );
};

const SidebarIcon = ({ icon, active, onClick }) => (
    <button onClick={onClick} className={`p-4 rounded-2xl transition-all ${active ? 'bg-primary text-dark shadow-lg shadow-primary/20' : 'text-slate-500 hover:text-white'}`}>
        {icon}
    </button>
);

const BusIcon = ({ className }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" className={className}>
        <rect x="3" y="4" width="18" height="12" rx="2" />
        <path d="M7 20h.01" />
        <path d="M17 20h.01" />
        <path d="M6 8h12" />
        <path d="M6 12h12" />
    </svg>
);

export default Home;
