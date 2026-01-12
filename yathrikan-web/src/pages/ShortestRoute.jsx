import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { ArrowLeft, MapPin, Navigation2, Clock, TrendingUp } from 'lucide-react';
import Button from '../components/ui/Button';

const ShortestRoute = () => {
    const navigate = useNavigate();
    const [from, setFrom] = useState('');
    const [to, setTo] = useState('');
    const [routes, setRoutes] = useState([]);

    const findRoutes = (e) => {
        e.preventDefault();
        // Mock route data
        setRoutes([
            { id: 1, name: 'Route 42A', duration: '25 min', distance: '8.5 km', stops: 12, busCount: 3 },
            { id: 2, name: 'Route 15B', duration: '32 min', distance: '10.2 km', stops: 15, busCount: 2 },
            { id: 3, name: 'Route 7C', duration: '28 min', distance: '9.1 km', stops: 14, busCount: 4 }
        ]);
    };

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen bg-slate-50 pb-24"
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
                <h1 className="text-2xl font-black text-dark text-center">Shortest Route</h1>
            </header>

            <div className="p-6 max-w-2xl mx-auto space-y-6">
                {/* Route Search Form */}
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    className="bg-white rounded-[32px] p-6 shadow-lg"
                >
                    <form onSubmit={findRoutes} className="space-y-4">
                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">FROM</label>
                            <div className="relative">
                                <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <input
                                    type="text"
                                    value={from}
                                    onChange={(e) => setFrom(e.target.value)}
                                    required
                                    placeholder="Enter starting location"
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900"
                                />
                            </div>
                        </div>

                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">TO</label>
                            <div className="relative">
                                <Navigation2 className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <input
                                    type="text"
                                    value={to}
                                    onChange={(e) => setTo(e.target.value)}
                                    required
                                    placeholder="Enter destination"
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900"
                                />
                            </div>
                        </div>

                        <Button type="submit" className="w-full py-4 text-lg">
                            Find Routes
                        </Button>
                    </form>
                </motion.div>

                {/* Route Results */}
                {routes.length > 0 && (
                    <div className="space-y-4">
                        <h2 className="text-xl font-black text-dark px-2">Available Routes</h2>
                        {routes.map((route, index) => (
                            <motion.div
                                key={route.id}
                                initial={{ x: -20, opacity: 0 }}
                                animate={{ x: 0, opacity: 1 }}
                                transition={{ delay: index * 0.1 }}
                                className="bg-white rounded-[24px] p-6 shadow-sm hover:shadow-md transition-shadow"
                            >
                                <div className="flex items-start justify-between mb-4">
                                    <div>
                                        <h3 className="text-lg font-black text-dark">{route.name}</h3>
                                        <p className="text-sm text-slate-500 font-medium">{route.busCount} buses available</p>
                                    </div>
                                    <div className="bg-primary px-4 py-2 rounded-full">
                                        <span className="text-dark font-black text-sm">FASTEST</span>
                                    </div>
                                </div>

                                <div className="grid grid-cols-3 gap-4">
                                    <div className="flex items-center gap-2">
                                        <Clock className="text-primary" size={16} />
                                        <span className="text-sm font-bold text-dark">{route.duration}</span>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <TrendingUp className="text-primary" size={16} />
                                        <span className="text-sm font-bold text-dark">{route.distance}</span>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <MapPin className="text-primary" size={16} />
                                        <span className="text-sm font-bold text-dark">{route.stops} stops</span>
                                    </div>
                                </div>

                                <Button variant="outline" className="w-full mt-4">
                                    Select Route
                                </Button>
                            </motion.div>
                        ))}
                    </div>
                )}
            </div>
        </motion.div>
    );
};

export default ShortestRoute;
