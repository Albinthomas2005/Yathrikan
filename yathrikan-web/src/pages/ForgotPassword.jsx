import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import Button from '../components/ui/Button';
import { Mail, ArrowLeft, CheckCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const ForgotPassword = () => {
    const navigate = useNavigate();
    const { resetPassword } = useAuth();
    const [isLoading, setIsLoading] = useState(false);
    const [emailSent, setEmailSent] = useState(false);
    const [email, setEmail] = useState('');
    const [error, setError] = useState('');

    const handleResetPassword = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await resetPassword(email);
            setEmailSent(true);
        } catch (err) {
            setError(err.message || 'Failed to send reset email');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="min-h-screen bg-primary flex items-center justify-center p-8"
        >
            <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className="w-full max-w-md bg-white rounded-[40px] p-10 shadow-2xl relative"
            >
                <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => navigate('/login')}
                    className="absolute top-8 left-8 p-3 bg-slate-100 rounded-full text-dark hover:bg-slate-200 transition-colors"
                >
                    <ArrowLeft size={20} />
                </motion.button>

                {!emailSent ? (
                    <>
                        <div className="text-center mt-12 mb-8">
                            <h1 className="text-3xl font-black text-dark">Forgot Password?</h1>
                            <p className="mt-3 text-slate-500 font-medium">
                                No worries! Enter your email and we'll send you reset instructions.
                            </p>
                        </div>

                        {error && (
                            <div className="bg-red-50 border-2 border-red-200 rounded-2xl p-4 mb-6">
                                <p className="text-red-600 text-sm font-medium">{error}</p>
                            </div>
                        )}

                        <form onSubmit={handleResetPassword} className="space-y-6">
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

                            <Button
                                type="submit"
                                disabled={isLoading}
                                className="w-full py-5 text-lg shadow-xl"
                            >
                                {isLoading ? 'Sending...' : 'Send Reset Link'}
                            </Button>
                        </form>
                    </>
                ) : (
                    <div className="text-center py-8">
                        <motion.div
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6"
                        >
                            <CheckCircle size={48} className="text-green-600" />
                        </motion.div>
                        <h2 className="text-2xl font-black text-dark mb-3">Check Your Email!</h2>
                        <p className="text-slate-500 font-medium mb-8">
                            We've sent password reset instructions to <span className="font-bold text-dark">{email}</span>
                        </p>
                        <Button
                            onClick={() => navigate('/login')}
                            className="w-full py-4"
                        >
                            Back to Login
                        </Button>
                    </div>
                )}
            </motion.div>
        </motion.div>
    );
};

export default ForgotPassword;
