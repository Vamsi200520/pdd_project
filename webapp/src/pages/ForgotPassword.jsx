import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Wind, Mail, Lock, Loader2, AlertCircle, ChevronLeft, CheckCircle2, ShieldAlert } from 'lucide-react';
import { motion } from 'framer-motion';
import { authService } from '../services/api';

const ForgotPassword = () => {
    const navigate = useNavigate();
    const [email, setEmail] = useState('');
    const [otp, setOtp] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [fieldErrors, setFieldErrors] = useState({});
    const [otpSent, setOtpSent] = useState(false);
    const [resetComplete, setResetComplete] = useState(false);

    const handleSendOtp = async (e) => {
        e.preventDefault();
        
        // Basic email validation
        if (!email.trim()) {
            setError('Please enter your email');
            return;
        }
        const emailRegex = /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/i;
        if (!emailRegex.test(email)) {
            setError('Please enter a valid email address');
            return;
        }

        setIsLoading(true);
        setError('');
        try {
            await authService.forgotPassword(email);
            setIsLoading(false);
            setOtpSent(true);
        } catch (err) {
            setIsLoading(false);
            setError(err.response?.data?.error || err.response?.data?.detail || 'Failed to send recovery code. Please check your email.');
        }
    };

    const handleResetPassword = async (e) => {
        e.preventDefault();
        setError('');
        setFieldErrors({});

        const errors = {};
        if (otp.length !== 6) {
            errors.otp = 'Please enter a valid 6-digit OTP';
        }
        if (!newPassword) {
            errors.newPassword = 'Password is required';
        } else if (newPassword.length < 6) {
            errors.newPassword = 'Password must be at least 6 characters';
        }
        if (newPassword !== confirmPassword) {
            errors.confirmPassword = 'Passwords do not match';
        }

        if (Object.keys(errors).length > 0) {
            setFieldErrors(errors);
            return;
        }

        setIsLoading(true);
        try {
            await authService.resetPassword(email, otp, newPassword);
            setIsLoading(false);
            setResetComplete(true);
        } catch (err) {
            setIsLoading(false);
            setError(err.response?.data?.error || err.response?.data?.detail || 'Password reset failed. Please check your OTP.');
        }
    };

    const containerStyle = {
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#134e4a',
        fontFamily: 'system-ui, -apple-system, sans-serif',
        padding: '2rem',
        boxSizing: 'border-box'
    };

    const cardStyle = {
        width: '100%',
        maxWidth: '440px',
        backgroundColor: '#ffffff',
        borderRadius: '2rem',
        padding: '3rem',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
    };

    const inputStyle = (hasError) => ({
        width: '100%',
        height: '56px',
        padding: '0 16px 0 52px',
        border: hasError ? '2px solid #dc2626' : '2px solid #e2e8f0',
        borderRadius: '16px',
        fontSize: '1rem',
        fontWeight: '600',
        boxSizing: 'border-box',
        outline: 'none',
        color: '#0f172a'
    });

    const errorLabelStyle = {
        color: '#dc2626',
        fontSize: '0.75rem',
        fontWeight: '700',
        marginTop: '4px'
    };

    return (
        <div style={containerStyle}>
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                style={cardStyle}
            >
                {resetComplete ? (
                    // STEP 3: SUCCESS STATE
                    <>
                        <div style={{ padding: '1.25rem', backgroundColor: '#e6f4ea', borderRadius: '1.5rem', marginBottom: '2rem', color: '#137333' }}>
                            <CheckCircle2 size={48} />
                        </div>
                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: '0 0 1rem 0', textAlign: 'center' }}>Reset Successful</h2>
                        <p style={{ color: '#64748b', textAlign: 'center', lineHeight: '1.6', marginBottom: '3rem', fontWeight: '500' }}>
                            Your password has been reset successfully. You can now log in with your new credentials.
                        </p>
                        <button
                            onClick={() => navigate('/login')}
                            style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer' }}
                        >
                            LOGIN NOW
                        </button>
                    </>
                ) : otpSent ? (
                    // STEP 2: ENTER OTP AND NEW PASSWORD
                    <>
                        <div style={{ padding: '1.25rem', backgroundColor: '#134e4a', borderRadius: '1.5rem', marginBottom: '2rem', color: '#ffffff' }}>
                            <Wind size={40} />
                        </div>

                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: '0 0 1rem 0', textAlign: 'center' }}>Reset Password</h2>
                        <p style={{ color: '#64748b', textAlign: 'center', lineHeight: '1.6', marginBottom: '2rem', fontWeight: '500' }}>
                            Enter the 6-digit OTP sent to <br />
                            <strong style={{ color: '#134e4a' }}>{email}</strong> and configure your new password.
                        </p>

                        <form onSubmit={handleResetPassword} style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                            {/* OTP */}
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>6-DIGIT OTP</label>
                                <div style={{ position: 'relative' }}>
                                    <Lock size={22} style={{ position: 'absolute', left: '18px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                                    <input
                                        type="text"
                                        inputMode="numeric"
                                        value={otp}
                                        onChange={(e) => {
                                            setOtp(e.target.value.replace(/\D/g, '').slice(0, 6));
                                            if (fieldErrors.otp) setFieldErrors({ ...fieldErrors, otp: '' });
                                        }}
                                        placeholder="••••••"
                                        required
                                        style={inputStyle(!!fieldErrors.otp)}
                                    />
                                </div>
                                {fieldErrors.otp && <div style={errorLabelStyle}>{fieldErrors.otp}</div>}
                            </div>

                            {/* NEW PASSWORD */}
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>NEW PASSWORD</label>
                                <div style={{ position: 'relative' }}>
                                    <Lock size={22} style={{ position: 'absolute', left: '18px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                                    <input
                                        type="password"
                                        value={newPassword}
                                        onChange={(e) => {
                                            setNewPassword(e.target.value.slice(0, 30));
                                            if (fieldErrors.newPassword) setFieldErrors({ ...fieldErrors, newPassword: '' });
                                        }}
                                        placeholder="••••••••"
                                        required
                                        style={inputStyle(!!fieldErrors.newPassword)}
                                    />
                                </div>
                                {fieldErrors.newPassword && <div style={errorLabelStyle}>{fieldErrors.newPassword}</div>}
                            </div>

                            {/* CONFIRM PASSWORD */}
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>CONFIRM PASSWORD</label>
                                <div style={{ position: 'relative' }}>
                                    <Lock size={22} style={{ position: 'absolute', left: '18px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                                    <input
                                        type="password"
                                        value={confirmPassword}
                                        onChange={(e) => {
                                            setConfirmPassword(e.target.value.slice(0, 30));
                                            if (fieldErrors.confirmPassword) setFieldErrors({ ...fieldErrors, confirmPassword: '' });
                                        }}
                                        placeholder="••••••••"
                                        required
                                        style={inputStyle(!!fieldErrors.confirmPassword)}
                                    />
                                </div>
                                {fieldErrors.confirmPassword && <div style={errorLabelStyle}>{fieldErrors.confirmPassword}</div>}
                            </div>

                            {error && (
                                <div style={{ padding: '1rem', borderRadius: '1rem', backgroundColor: '#fff1f2', border: '1px solid #ffe4e6', display: 'flex', alignItems: 'center', gap: '0.75rem', boxSizing: 'border-box' }}>
                                    <AlertCircle size={20} color="#e11d48" />
                                    <span style={{ fontSize: '0.85rem', color: '#e11d48', fontWeight: '700' }}>{error}</span>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={isLoading}
                                style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer', boxShadow: '0 10px 15px -3px rgba(19, 78, 74, 0.3)', marginTop: '1rem' }}
                            >
                                {isLoading ? <Loader2 size={24} className="animate-spin" style={{ margin: 'auto' }} /> : 'RESET PASSWORD'}
                            </button>
                        </form>
                    </>
                ) : (
                    // STEP 1: ENTER EMAIL TO RECEIVE OTP
                    <>
                        <div style={{ padding: '1.25rem', backgroundColor: '#134e4a', borderRadius: '1.5rem', marginBottom: '2rem', color: '#ffffff' }}>
                            <Wind size={40} />
                        </div>

                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: '0 0 1rem 0', textAlign: 'center' }}>Account Recovery</h2>
                        <p style={{ color: '#64748b', textAlign: 'center', lineHeight: '1.6', marginBottom: '3rem', fontWeight: '500' }}>
                            Enter your registered email address below to receive a password reset code.
                        </p>

                        <form onSubmit={handleSendOtp} style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.15em' }}>EMAIL ADDRESS</label>
                                <div style={{ position: 'relative' }}>
                                    <Mail size={22} style={{ position: 'absolute', left: '18px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                                    <input
                                        type="email"
                                        value={email}
                                        onChange={(e) => {
                                            setEmail(e.target.value.toLowerCase().replace(/\s/g, '').slice(0, 80));
                                            setError('');
                                        }}
                                        placeholder="email@example.com"
                                        required
                                        style={inputStyle(!!error)}
                                    />
                                </div>
                            </div>

                            {error && (
                                <div style={{ padding: '1rem', borderRadius: '1rem', backgroundColor: '#fff1f2', border: '1px solid #ffe4e6', display: 'flex', alignItems: 'center', gap: '0.75rem', boxSizing: 'border-box' }}>
                                    <AlertCircle size={20} color="#e11d48" />
                                    <span style={{ fontSize: '0.85rem', color: '#e11d48', fontWeight: '700' }}>{error}</span>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={isLoading}
                                style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer', boxShadow: '0 10px 15px -3px rgba(19, 78, 74, 0.3)' }}
                            >
                                {isLoading ? <Loader2 size={24} className="animate-spin" style={{ margin: 'auto' }} /> : 'SEND RECOVERY CODE'}
                            </button>
                        </form>
                    </>
                )}

                <button
                    onClick={() => navigate('/login')}
                    style={{ background: 'none', border: 'none', padding: 0, color: '#134e4a', fontWeight: '900', cursor: 'pointer', marginTop: '3rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                >
                    <ChevronLeft size={20} /> BACK TO LOGIN
                </button>
            </motion.div>
        </div>
    );
};

export default ForgotPassword;
