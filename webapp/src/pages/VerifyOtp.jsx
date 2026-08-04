import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Wind, Mail, Loader2, AlertCircle, ChevronLeft, CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { authService } from '../services/api';

const VerifyOtp = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const email = location.state?.email || '';

    const [otp, setOtp] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleChange = (e) => {
        // Only allow numbers and limit to 6 digits
        const val = e.target.value.replace(/\D/g, '').slice(0, 6);
        setOtp(val);
        setError('');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (otp.length !== 6) {
            setError('Please enter a valid 6-digit OTP');
            return;
        }

        setIsLoading(true);
        setError('');
        try {
            await authService.verifySignupOtp(email, otp);
            setIsLoading(false);
            setSuccess(true);
        } catch (err) {
            setIsLoading(false);
            setError(err.response?.data?.error || err.response?.data?.detail || 'OTP verification failed.');
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

    const inputStyle = {
        width: '100%',
        height: '56px',
        textAlign: 'center',
        letterSpacing: '0.5em',
        fontSize: '1.5rem',
        fontWeight: '700',
        border: '2px solid #e2e8f0',
        borderRadius: '16px',
        boxSizing: 'border-box',
        outline: 'none',
        color: '#0f172a',
        paddingLeft: '0.25em' // compensate for letter spacing
    };

    if (!email) {
        return (
            <div style={containerStyle}>
                <div style={cardStyle}>
                    <AlertCircle size={48} color="#dc2626" style={{ marginBottom: '1.5rem' }} />
                    <h2 style={{ fontSize: '1.5rem', fontWeight: '900', color: '#0f172a', marginBottom: '1rem' }}>No Email Context</h2>
                    <p style={{ color: '#64748b', textAlign: 'center', marginBottom: '2rem' }}>Please register first to verify your email.</p>
                    <button onClick={() => navigate('/signup')} style={{ width: '100%', height: '56px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '12px', fontWeight: '800', cursor: 'pointer' }}>Go to Signup</button>
                </div>
            </div>
        );
    }

    return (
        <div style={containerStyle}>
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                style={cardStyle}
            >
                {!success ? (
                    <>
                        <div style={{ padding: '1.25rem', backgroundColor: '#134e4a', borderRadius: '1.5rem', marginBottom: '2rem', color: '#ffffff' }}>
                            <Wind size={40} />
                        </div>

                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: '0 0 1rem 0', textAlign: 'center' }}>Verify OTP</h2>
                        <p style={{ color: '#64748b', textAlign: 'center', lineHeight: '1.6', marginBottom: '2.5rem', fontWeight: '500' }}>
                            Enter the 6-digit code sent to <br />
                            <strong style={{ color: '#134e4a' }}>{email}</strong>
                        </p>

                        <form onSubmit={handleSubmit} style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', alignItems: 'center' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.15em' }}>6-DIGIT CODE</label>
                                <input
                                    type="text"
                                    inputMode="numeric"
                                    value={otp}
                                    onChange={handleChange}
                                    placeholder="••••••"
                                    required
                                    style={inputStyle}
                                />
                            </div>

                            {error && (
                                <div style={{ padding: '1rem', borderRadius: '1rem', backgroundColor: '#fff1f2', border: '1px solid #ffe4e6', display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%', boxSizing: 'border-box' }}>
                                    <AlertCircle size={20} color="#e11d48" />
                                    <span style={{ fontSize: '0.85rem', color: '#e11d48', fontWeight: '700' }}>{error}</span>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={isLoading || otp.length !== 6}
                                style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer', opacity: (otp.length !== 6 || isLoading) ? 0.6 : 1, transition: 'all 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                            >
                                {isLoading ? <Loader2 size={24} className="animate-spin" /> : 'VERIFY CODE'}
                            </button>
                        </form>
                    </>
                ) : (
                    <>
                        <div style={{ padding: '1.25rem', backgroundColor: '#e6f4ea', borderRadius: '1.5rem', marginBottom: '2rem', color: '#137333' }}>
                            <CheckCircle2 size={48} />
                        </div>
                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: '0 0 1rem 0', textAlign: 'center' }}>Email Verified</h2>
                        <p style={{ color: '#64748b', textAlign: 'center', lineHeight: '1.6', marginBottom: '3rem', fontWeight: '500' }}>
                            Your email has been successfully verified. You can now login.
                        </p>
                        <button
                            onClick={() => navigate('/login')}
                            style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer' }}
                        >
                            LOGIN NOW
                        </button>
                    </>
                )}

                {!success && (
                    <button
                        onClick={() => navigate('/signup')}
                        style={{ background: 'none', border: 'none', padding: 0, color: '#134e4a', fontWeight: '900', cursor: 'pointer', marginTop: '3rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                    >
                        <ChevronLeft size={20} /> BACK TO SIGNUP
                    </button>
                )}
            </motion.div>
        </div>
    );
};

export default VerifyOtp;
