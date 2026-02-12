import { motion } from 'framer-motion';

const Button = ({ children, className = '', variant = 'primary', ...props }) => {
    const variants = {
        primary: 'bg-dark text-primary hover:bg-slate-800',
        secondary: 'bg-primary text-dark hover:bg-yellow-500',
        outline: 'border-2 border-dark text-dark hover:bg-dark hover:text-white',
        ghost: 'text-dark hover:bg-slate-100',
    };

    return (
        <motion.button
            whileTap={{ scale: 0.95 }}
            whileHover={{ scale: 1.02 }}
            className={`px-6 py-3 rounded-2xl font-bold transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
            {...props}
        >
            {children}
        </motion.button>
    );
};

export default Button;
