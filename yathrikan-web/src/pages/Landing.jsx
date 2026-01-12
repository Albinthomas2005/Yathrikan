import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import Button from '../components/ui/Button';
import { ArrowRight, Bus } from 'lucide-react';

const Landing = () => {
    const navigate = useNavigate();

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0, x: -20 }}
            className="min-h-screen bg-primary flex flex-col overflow-hidden"
        >
            {/* Top Branding Section */}
            <div className="flex-[3] flex flex-col items-center justify-center p-8">
                <motion.div
                    initial={{ scale: 0, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ type: 'spring', duration: 0.6, bounce: 0.4 }}
                    className="w-48 h-48 bg-dark rounded-full flex items-center justify-center shadow-2xl relative"
                >
                    <Bus size={80} className="text-primary" />
                    <motion.div
                        animate={{ scale: [1, 1.2, 1], opacity: [0.2, 0.4, 0.2] }}
                        transition={{ repeat: Infinity, duration: 2 }}
                        className="absolute inset-0 bg-dark rounded-full -z-10"
                    />
                </motion.div>

                <motion.h1
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.3 }}
                    className="mt-8 text-5xl font-black text-dark tracking-tighter"
                >
                    YATHRIKAN
                </motion.h1>

                <motion.p
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.4 }}
                    className="mt-2 text-dark/70 font-medium text-lg uppercase tracking-widest"
                >
                    Smart Public Transport Assistant
                </motion.p>
            </div>

            {/* Bottom Content Card */}
            <motion.div
                initial={{ y: '100%' }}
                animate={{ y: 0 }}
                transition={{ type: 'spring', damping: 20, stiffness: 100 }}
                className="flex-[2] bg-white rounded-t-[40px] p-10 flex flex-col items-center justify-between shadow-[0_-20px_50px_rgba(0,0,0,0.1)]"
            >
                <div className="text-center max-w-sm">
                    <motion.h2
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.6 }}
                        className="text-2xl font-extrabold text-slate-900 leading-tight"
                    >
                        Your Smart Transport Companion
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.7 }}
                        className="mt-4 text-slate-500 font-medium"
                    >
                        Track buses in real-time, buy tickets digitally, and travel hassle-free.
                    </motion.p>
                </div>

                <motion.div
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.8 }}
                    className="w-full"
                >
                    <Button
                        variant="primary"
                        className="w-full py-5 text-xl flex items-center justify-center gap-2 group"
                        onClick={() => navigate('/login')}
                    >
                        Get Started
                        <ArrowRight className="group-hover:translate-x-1 transition-transform" />
                    </Button>
                </motion.div>
            </motion.div>
        </motion.div>
    );
};

export default Landing;
