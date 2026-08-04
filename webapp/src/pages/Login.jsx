import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Navigate, useNavigate } from 'react-router-dom';
import { Wind, Mail, Lock, Loader2, AlertCircle } from 'lucide-react';
import { motion } from 'framer-motion';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [selectedRole, setSelectedRole] = useState('');
    const { login, token } = useAuth();
    const navigate = useNavigate();

    if (token) {
        return <Navigate to="/" replace />;
    }

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (!selectedRole) {
            setError('Please select your identity (PATIENT or DOCTOR) to continue.');
            return;
        }

        setIsLoading(true);
        setError('');

        try {
            await login(email, password, selectedRole);
        } catch (err) {
            setError(err.message || err.response?.data?.detail || 'Login failed. Please check your credentials.');
        } finally {
            setIsLoading(false);
        }
    };

    const inputStyle = {
        width: '100%',
        height: '56px',
        padding: '0 20px 0 52px',
        border: '2px solid #e2e8f0',
        borderRadius: '16px',
        fontSize: '1rem',
        fontWeight: '600',
        boxSizing: 'border-box',
        outline: 'none',
        backgroundColor: '#ffffff',
        color: '#0f172a', // Explicitly dark color so text is visible
        transition: 'all 0.2s ease',
        position: 'relative',
        zIndex: 2
    };

    const iconWrapperStyle = {
        position: 'absolute',
        left: '18px',
        top: '50%',
        transform: 'translateY(-50%)',
        display: 'flex',
        alignItems: 'center',
        color: '#94a3b8',
        pointerEvents: 'none',
        zIndex: 3
    };

    return (
        <div style={{ display: 'flex', minHeight: '100vh', width: '100vw', backgroundColor: '#ffffff', fontFamily: 'system-ui, -apple-system, sans-serif' }}>

            {/* LEFT HERO PANEL */}
            <div style={{ width: '50%', backgroundColor: '#134e4a', color: '#ffffff', padding: '4rem', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', boxSizing: 'border-box', position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, background: 'radial-gradient(circle at 10% 10%, rgba(45, 122, 126, 0.4) 0%, transparent 70%)', pointerEvents: 'none' }}></div>

                <div style={{ position: 'relative', zIndex: 10 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '4rem' }}>
                        <div style={{ padding: '0.5rem', backgroundColor: 'rgba(255,255,255,0.15)', borderRadius: '0.75rem' }}>
                            <Wind size={24} />
                        </div>
                        <span style={{ fontSize: '1.25rem', fontWeight: '900', letterSpacing: '0.15em', textTransform: 'uppercase' }}>PEFR TITRATION</span>
                    </div>

                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                    >
                        <h1 style={{ fontSize: '4.5rem', fontWeight: '900', lineHeight: '1', marginBottom: '2rem', letterSpacing: '-0.04em' }}>
                            Master Your <br />
                            <span style={{ color: '#4db6ac' }}>Respiratory Health.</span>
                        </h1>
                        <p style={{ fontSize: '1.35rem', color: '#b2dfdb', maxWidth: '480px', lineHeight: '1.5', fontWeight: '400' }}>
                            The professional clinical standard for peak flow analysis and treatment optimization.
                        </p>
                    </motion.div>
                </div>

                <div style={{ position: 'relative', zIndex: 10, display: 'flex', gap: '6rem' }}>
                    <div>
                        <div style={{ fontSize: '3rem', fontWeight: '900' }}>98%</div>
                        <div style={{ fontSize: '0.75rem', color: '#4db6ac', letterSpacing: '0.2em', fontWeight: '900' }}>CLINICAL ACCURACY</div>
                    </div>
                    <div>
                        <div style={{ fontSize: '3rem', fontWeight: '900' }}>AI</div>
                        <div style={{ fontSize: '0.75rem', color: '#4db6ac', letterSpacing: '0.2em', fontWeight: '900' }}>SMART INSIGHTS</div>
                    </div>
                </div>
            </div>

            {/* RIGHT FORM PANEL */}
            <div style={{ width: '50%', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '4rem', boxSizing: 'border-box', backgroundColor: '#fdfdfd' }}>
                <div style={{ width: '100%', maxWidth: '420px' }}>

                    {/* LOGO BLOCK */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', alignItems: 'center', textAlign: 'center', marginBottom: '4rem' }}>
                        <div style={{ width: '80px', height: '80px', backgroundColor: '#134e4a', color: '#ffffff', borderRadius: '1.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 20px 25px -5px rgba(19, 78, 74, 0.2)', transform: 'rotate(-2deg)' }}>
                            <Wind size={40} />
                        </div>
                        <div>
                            <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', letterSpacing: '-0.03em', margin: 0 }}>Welcome Back</h2>
                            <p style={{ fontSize: '1rem', color: '#64748b', margin: '6px 0 0 0', fontWeight: '500' }}>Please enter your workstation details.</p>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '2.25rem' }}>

                        {/* IDENTITY SELECTOR (Updated to match iOS) */}
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>SELECT IDENTITY</label>
                            <div style={{ display: 'flex', backgroundColor: '#f1f5f9', padding: '6px', borderRadius: '16px' }}>
                                <button
                                    type="button"
                                    onClick={() => setSelectedRole('patient')}
                                    style={{ flex: 1, padding: '12px', borderRadius: '12px', border: 'none', fontWeight: '800', fontSize: '0.8rem', backgroundColor: selectedRole === 'patient' ? '#ffffff' : 'transparent', color: selectedRole === 'patient' ? '#134e4a' : '#94a3b8', boxShadow: selectedRole === 'patient' ? '0 10px 15px -3px rgba(0, 0, 0, 0.1)' : 'none', cursor: 'pointer', transition: 'all 0.2s' }}
                                >
                                    PATIENT
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setSelectedRole('doctor')}
                                    style={{ flex: 1, padding: '12px', borderRadius: '12px', border: 'none', fontWeight: '800', fontSize: '0.8rem', backgroundColor: selectedRole === 'doctor' ? '#ffffff' : 'transparent', color: selectedRole === 'doctor' ? '#134e4a' : '#94a3b8', boxShadow: selectedRole === 'doctor' ? '0 10px 15px -3px rgba(0, 0, 0, 0.1)' : 'none', cursor: 'pointer', transition: 'all 0.2s' }}
                                >
                                    DOCTOR
                                </button>
                            </div>
                        </div>

                        {/* EMAIL */}
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>EMAIL ADDRESS</label>
                            <div style={{ position: 'relative' }}>
                                <div style={iconWrapperStyle}><Mail size={22} /></div>
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    placeholder="email@example.com"
                                    required
                                    style={inputStyle}
                                />
                            </div>
                        </div>

                        {/* PASSWORD */}
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.1em' }}>PASSWORD</label>
                            <div style={{ position: 'relative' }}>
                                <div style={iconWrapperStyle}><Lock size={22} /></div>
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="********"
                                    required
                                    style={inputStyle}
                                />
                            </div>
                        </div>

                        {error && (
                            <div style={{ padding: '1rem', borderRadius: '1rem', backgroundColor: '#fff1f2', border: '1px solid #ffe4e6', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                                <AlertCircle size={20} color="#e11d48" />
                                <span style={{ fontSize: '0.85rem', color: '#e11d48', fontWeight: '700' }}>{error}</span>
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={isLoading}
                            style={{ width: '100%', height: '64px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1.1rem', cursor: 'pointer', boxShadow: '0 10px 15px -3px rgba(19, 78, 74, 0.3)', transition: 'all 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: '1rem' }}
                        >
                            {isLoading ? <Loader2 size={24} className="animate-spin" /> : 'LOGIN'}
                        </button>
                    </form>

                    {/* NAVIGATION LINKS (Updated to match iOS) */}
                    <div style={{ textAlign: 'center', marginTop: '3rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                        <button
                            onClick={() => navigate('/forgot-password')}
                            style={{ background: 'none', border: 'none', padding: 0, fontSize: '0.9rem', fontWeight: '700', color: '#134e4a', cursor: 'pointer' }}
                        >
                            Forgot Password?
                        </button>
                        <p style={{ fontSize: '0.95rem', color: '#64748b', fontWeight: '500', margin: 0 }}>
                            Don't have an account? <button onClick={() => navigate('/signup')} style={{ background: 'none', border: 'none', padding: 0, color: '#4db6ac', fontWeight: '900', cursor: 'pointer' }}>Sign Up</button>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Login;
