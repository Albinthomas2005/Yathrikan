import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Ticket, MapPin, Calendar, QrCode, Plus } from 'lucide-react';
import Button from '../components/ui/Button';

const MyTickets = () => {
    const navigate = useNavigate();

    const tickets = [
        { id: 1, route: 'Route 42A', from: 'Central Station', to: 'Airport', date: '2026-01-08', time: '14:30', price: '₹45', status: 'active' },
        { id: 2, route: 'Route 15B', from: 'Bus Stand', to: 'Tech Park', date: '2026-01-07', time: '09:15', price: '₹30', status: 'used' },
        { id: 3, route: 'Route 7C', from: 'Mall Road', to: 'Railway Station', date: '2026-01-06', time: '18:45', price: '₹25', status: 'expired' }
    ];

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
                <h1 className="text-2xl font-black text-dark text-center">My Tickets</h1>
            </header>

            <div className="p-6 max-w-2xl mx-auto space-y-6">
                {/* Buy New Ticket Button */}
                <motion.div
                    initial={{ y: -20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                >
                    <Button className="w-full py-5 text-lg flex items-center justify-center gap-2">
                        <Plus size={24} />
                        Buy New Ticket
                    </Button>
                </motion.div>

                {/* Tickets List */}
                <div className="space-y-4">
                    {tickets.map((ticket, index) => (
                        <motion.div
                            key={ticket.id}
                            initial={{ x: -20, opacity: 0 }}
                            animate={{ x: 0, opacity: 1 }}
                            transition={{ delay: index * 0.1 }}
                            className={`bg-white rounded-[32px] p-6 shadow-lg relative overflow-hidden ${ticket.status === 'active' ? 'border-2 border-primary' : ''
                                }`}
                        >
                            {/* Status Badge */}
                            <div className={`absolute top-6 right-6 px-3 py-1 rounded-full text-xs font-black uppercase ${ticket.status === 'active' ? 'bg-green-100 text-green-700' :
                                    ticket.status === 'used' ? 'bg-slate-100 text-slate-600' :
                                        'bg-red-100 text-red-600'
                                }`}>
                                {ticket.status}
                            </div>

                            {/* Ticket Info */}
                            <div className="space-y-4 pr-20">
                                <div>
                                    <h3 className="text-xl font-black text-dark">{ticket.route}</h3>
                                    <div className="flex items-center gap-2 mt-2 text-slate-600">
                                        <MapPin size={16} className="text-primary" />
                                        <span className="text-sm font-medium">{ticket.from} → {ticket.to}</span>
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="flex items-center gap-2">
                                        <Calendar size={16} className="text-primary" />
                                        <div>
                                            <p className="text-xs text-slate-500 font-bold">DATE</p>
                                            <p className="text-sm font-bold text-dark">{ticket.date}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <Ticket size={16} className="text-primary" />
                                        <div>
                                            <p className="text-xs text-slate-500 font-bold">PRICE</p>
                                            <p className="text-sm font-bold text-dark">{ticket.price}</p>
                                        </div>
                                    </div>
                                </div>

                                {ticket.status === 'active' && (
                                    <Button variant="outline" className="w-full flex items-center justify-center gap-2">
                                        <QrCode size={20} />
                                        Show QR Code
                                    </Button>
                                )}
                            </div>
                        </motion.div>
                    ))}
                </div>
            </div>
        </motion.div>
    );
};

export default MyTickets;
