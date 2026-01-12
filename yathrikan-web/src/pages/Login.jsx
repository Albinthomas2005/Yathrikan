import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import Button from '../components/ui/Button';
import { Mail, Lock, Eye, EyeOff, ArrowLeft } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const Login = () => {
    const navigate = useNavigate();
    const { login, loginWithGoogle } = useAuth();
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await login(email, password);
            navigate('/home');
        } catch (err) {
            setError(err.message || 'Failed to login. Please check your credentials.');
        } finally {
            setIsLoading(false);
        }
    };

    const handleGoogleLogin = async () => {
        setError('');
        setIsLoading(true);

        try {
            await loginWithGoogle();
            navigate('/home');
        } catch (err) {
            setError(err.message || 'Failed to login with Google.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="min-h-screen bg-primary flex flex-col lg:flex-row overflow-hidden"
        >
            {/* Mobile Header / Desktop Side Branding */}
            <div className="lg:flex-1 p-8 flex flex-col justify-center items-center lg:items-start lg:p-20 relative overflow-hidden">
                <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => navigate('/')}
                    className="absolute top-8 left-8 p-3 bg-white/30 backdrop-blur-md rounded-full text-dark lg:hidden"
                >
                    <ArrowLeft size={24} />
                </motion.button>

                <motion.div
                    initial={{ opacity: 0, x: -50 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="z-10 text-center lg:text-left"
                >
                    <h1 className="text-4xl lg:text-7xl font-black text-dark leading-none">SIGN IN</h1>
                    <p className="mt-4 text-dark/70 font-semibold text-lg lg:max-w-md">
                        Welcome back to Yathrikan. Your digital transit world is just a few clicks away.
                    </p>
                </motion.div>

                {/* Decorative elements for desktop */}
                <div className="hidden lg:block absolute -right-20 top-1/2 -translate-y-1/2 w-64 h-64 bg-dark/5 rounded-full blur-3xl" />
            </div>

            {/* Login Form Container */}
            <motion.div
                initial={{ x: '100%' }}
                animate={{ x: 0 }}
                className="flex-[2] bg-white lg:rounded-l-[60px] p-8 lg:p-20 shadow-2xl flex items-center justify-center relative overflow-y-auto"
            >
                <div className="w-full max-w-md">
                    <form onSubmit={handleLogin} className="space-y-6">
                        <div className="space-y-2 text-center lg:text-left mb-10">
                            <h2 className="text-3xl font-bold text-slate-900">Get Moving</h2>
                            <p className="text-slate-500 font-medium">Enter your credentials to continue</p>
                        </div>

                        {error && (
                            <div className="bg-red-50 border-2 border-red-200 rounded-2xl p-4">
                                <p className="text-red-600 text-sm font-medium">{error}</p>
                            </div>
                        )}

                        {/* Email Field */}
                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">EMAIL ADDRESS</label>
                            <div className="relative">
                                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    placeholder="name@company.com"
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900"
                                />
                            </div>
                        </div>

                        {/* Password Field */}
                        <div className="space-y-2 group">
                            <div className="flex justify-between items-center ml-4">
                                <label className="text-sm font-bold text-slate-700">PASSWORD</label>
                                <button type="button" onClick={() => navigate('/forgot-password')} className="text-xs font-bold text-slate-400 hover:text-dark transition-colors">FORGOT?</button>
                            </div>
                            <div className="relative">
                                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    placeholder="••••••••"
                                    className="w-full pl-12 pr-12 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-dark transition-colors"
                                >
                                    {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                                </button>
                            </div>
                        </div>

                        <Button
                            type="submit"
                            disabled={isLoading}
                            className="w-full py-5 text-lg mt-4 shadow-xl"
                        >
                            {isLoading ? 'Scanning Securely...' : 'Sign In Now'}
                        </Button>

                        <div className="relative py-4 flex items-center gap-4">
                            <div className="flex-1 h-px bg-slate-200" />
                            <span className="text-xs font-bold text-slate-400">OR CONNECT WITH</span>
                            <div className="flex-1 h-px bg-slate-200" />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <Button
                                type="button"
                                onClick={handleGoogleLogin}
                                disabled={isLoading}
                                variant="outline"
                                className="flex items-center justify-center gap-2 font-bold text-sm bg-slate-50 border-transparent"
                            >
                                <img src="https://www.google.com/favicon.ico" className="w-4 h-4" alt="G" />
                                GOOGLE
                            </Button>
                            <Button variant="outline" className="flex items-center justify-center gap-2 font-bold text-sm bg-slate-50 border-transparent">
                                <span className="text-dark"></span>
                                APPLE
                            </Button>
                        </div>

                        <p className="text-center text-slate-500 font-medium text-sm pt-6">
                            Don't have an account? <button type="button" onClick={() => navigate('/signup')} className="text-dark font-black hover:underline underline-offset-4">SIGN UP</button>
                        </p>
                    </form>
                </div>
            </motion.div>
        </motion.div>
    );
};

export default Login;
