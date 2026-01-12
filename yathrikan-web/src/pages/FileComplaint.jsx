import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { ArrowLeft, AlertCircle, Bus, Camera, FileText } from 'lucide-react';
import Button from '../components/ui/Button';

const FileComplaint = () => {
    const navigate = useNavigate();
    const [busNumber, setBusNumber] = useState('');
    const [category, setCategory] = useState('');
    const [description, setDescription] = useState('');

    const categories = [
        'Rash Driving',
        'Bus Not Clean',
        'Driver Misbehavior',
        'Late Arrival',
        'Route Deviation',
        'AC Not Working',
        'Other'
    ];

    const handleSubmit = (e) => {
        e.preventDefault();
        alert('✅ Complaint submitted successfully! We will investigate and take action.');
        navigate('/home');
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
                <h1 className="text-2xl font-black text-dark text-center">File Complaint</h1>
            </header>

            <div className="p-6 max-w-2xl mx-auto">
                <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    className="bg-white rounded-[32px] p-6 shadow-lg"
                >
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {/* Bus Number */}
                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">BUS NUMBER</label>
                            <div className="relative">
                                <Bus className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <input
                                    type="text"
                                    value={busNumber}
                                    onChange={(e) => setBusNumber(e.target.value)}
                                    required
                                    placeholder="e.g., KL-01-AB-1234"
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900 uppercase"
                                />
                            </div>
                        </div>

                        {/* Category */}
                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">COMPLAINT CATEGORY</label>
                            <div className="relative">
                                <AlertCircle className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors z-10" size={20} />
                                <select
                                    value={category}
                                    onChange={(e) => setCategory(e.target.value)}
                                    required
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900 appearance-none"
                                >
                                    <option value="">Select a category</option>
                                    {categories.map((cat) => (
                                        <option key={cat} value={cat}>{cat}</option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        {/* Description */}
                        <div className="space-y-2 group">
                            <label className="text-sm font-bold text-slate-700 ml-4">DESCRIPTION</label>
                            <div className="relative">
                                <FileText className="absolute left-4 top-4 text-slate-400 group-focus-within:text-primary transition-colors" size={20} />
                                <textarea
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                    required
                                    placeholder="Describe the issue in detail..."
                                    rows={5}
                                    className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-transparent focus:border-primary focus:bg-white rounded-2xl outline-none transition-all font-medium text-slate-900 resize-none"
                                />
                            </div>
                        </div>

                        {/* Photo Upload */}
                        <div className="space-y-2">
                            <label className="text-sm font-bold text-slate-700 ml-4">UPLOAD PHOTO (OPTIONAL)</label>
                            <button
                                type="button"
                                className="w-full p-8 border-2 border-dashed border-slate-300 rounded-2xl hover:border-primary transition-colors flex flex-col items-center gap-2 text-slate-400 hover:text-primary"
                            >
                                <Camera size={32} />
                                <span className="font-medium">Click to upload photo</span>
                            </button>
                        </div>

                        <Button type="submit" className="w-full py-5 text-lg">
                            Submit Complaint
                        </Button>
                    </form>
                </motion.div>
            </div>
        </motion.div>
    );
};

export default FileComplaint;
