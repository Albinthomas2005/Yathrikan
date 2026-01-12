import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Shield, Phone, AlertTriangle, MapPin, Users } from 'lucide-react';
import Button from '../components/ui/Button';

const SafetyMonitor = () => {
    const navigate = useNavigate();

    const emergencyContacts = [
        { name: 'Police', number: '100', icon: <Shield /> },
        { name: 'Ambulance', number: '108', icon: <AlertTriangle /> },
        { name: 'Women Helpline', number: '1091', icon: <Users /> }
    ];

    const handleSOSClick = () => {
        if (window.confirm('🚨 This will send your location to emergency contacts and authorities. Proceed?')) {
            alert('✅ SOS Alert sent! Help is on the way. Stay calm and safe.');
        }
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
                <h1 className="text-2xl font-black text-dark text-center">Safety Monitor</h1>
            </header>

            <div className="p-6 max-w-2xl mx-auto space-y-6">
                {/* SOS Button */}
                <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: 'spring', duration: 0.6 }}
                    className="flex justify-center"
                >
                    <motion.button
                        whileTap={{ scale: 0.9 }}
                        onClick={handleSOSClick}
                        className="w-48 h-48 bg-gradient-to-br from-red-500 to-red-700 rounded-full shadow-2xl flex flex-col items-center justify-center text-white relative overflow-hidden group"
                    >
                        <motion.div
                            animate={{ scale: [1, 1.2, 1], opacity: [0.5, 0.8, 0.5] }}
                            transition={{ repeat: Infinity, duration: 2 }}
                            className="absolute inset-0 bg-red-400 rounded-full"
                        />
                        <Shield size={64} className="relative z-10 mb-2" />
                        <span className="relative z-10 text-3xl font-black">SOS</span>
                        <span className="relative z-10 text-sm font-medium">EMERGENCY</span>
                    </motion.button>
                </motion.div>

                <p className="text-center text-slate-600 font-medium px-4">
                    Press the SOS button in case of emergency. Your location will be shared with authorities.
                </p>

                {/* Current Location */}
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    className="bg-white rounded-[24px] p-6 shadow-lg"
                >
                    <div className="flex items-center gap-3 mb-3">
                        <div className="p-3 bg-primary rounded-full">
                            <MapPin className="text-dark" size={20} />
                        </div>
                        <h3 className="font-black text-dark">Current Location</h3>
                    </div>
                    <p className="text-slate-600 font-medium ml-14">
                        Central Station, Main Road, City Center
                    </p>
                    <Button variant="outline" className="w-full mt-4">
                        Share Location
                    </Button>
                </motion.div>

                {/* Emergency Contacts */}
                <div className="space-y-3">
                    <h2 className="text-xl font-black text-dark px-2">Emergency Contacts</h2>
                    {emergencyContacts.map((contact, index) => (
                        <motion.a
                            key={contact.number}
                            href={`tel:${contact.number}`}
                            initial={{ x: -20, opacity: 0 }}
                            animate={{ x: 0, opacity: 1 }}
                            transition={{ delay: index * 0.1 }}
                            className="bg-white rounded-[24px] p-6 shadow-sm flex items-center justify-between hover:shadow-md transition-shadow"
                        >
                            <div className="flex items-center gap-4">
                                <div className="p-3 bg-red-100 rounded-full text-red-600">
                                    {contact.icon}
                                </div>
                                <div>
                                    <h4 className="font-black text-dark">{contact.name}</h4>
                                    <p className="text-sm text-slate-500 font-medium">Emergency Service</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <Phone className="text-primary" size={20} />
                                <span className="text-lg font-black text-dark">{contact.number}</span>
                            </div>
                        </motion.a>
                    ))}
                </div>

                {/* Safety Tips */}
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.4 }}
                    className="bg-slate-100 rounded-[24px] p-6"
                >
                    <h3 className="font-black text-dark mb-3 flex items-center gap-2">
                        <AlertTriangle className="text-primary" size={20} />
                        Safety Tips
                    </h3>
                    <ul className="space-y-2 text-sm text-slate-600 font-medium">
                        <li>• Always sit near the driver or conductor</li>
                        <li>• Keep emergency contacts saved</li>
                        <li>• Share your journey with family/friends</li>
                        <li>• Stay alert and aware of surroundings</li>
                    </ul>
                </motion.div>
            </div>
        </motion.div>
    );
};

export default SafetyMonitor;
