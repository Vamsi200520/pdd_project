import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Wind, User, Mail, Lock, Phone, MapPin, Calendar, Ruler, Loader2, AlertCircle, ChevronLeft } from 'lucide-react';
import { motion } from 'framer-motion';
import { authService } from '../services/api';

const Signup = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        password: '',
        age: '',
        height: '',
        gender: 'Male',
        contactInfo: '',
        address: '',
        role: ''
    });
    const [fieldErrors, setFieldErrors] = useState({});
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    const handleChange = (e) => {
        const { name, value } = e.target;
        let updatedValue = value;

        // Apply strict filtering and limits identical to iOS app
        if (name === 'contactInfo') {
            updatedValue = value.replace(/\D/g, '').slice(0, 10);
        } else if (name === 'fullName') {
            updatedValue = value.replace(/[^a-zA-Z\s]/g, '').slice(0, 50);
        } else if (name === 'age') {
            updatedValue = value.replace(/\D/g, '').slice(0, 3);
        } else if (name === 'height') {
            updatedValue = value.replace(/\D/g, '').slice(0, 3);
        } else if (name === 'address') {
            updatedValue = value.slice(0, 150);
        } else if (name === 'email') {
            updatedValue = value.toLowerCase().replace(/\s/g, '').slice(0, 80);
        } else if (name === 'password') {
            updatedValue = value.slice(0, 30);
        }

        setFormData({ ...formData, [name]: updatedValue });
        
        // Clear field-specific error as user types
        if (fieldErrors[name]) {
            setFieldErrors({ ...fieldErrors, [name]: '' });
        }
    };

    const validateForm = () => {
        const errors = {};
        const { fullName, email, password, age, height, contactInfo, address } = formData;

        // Name validation
        if (!fullName.trim()) {
            errors.fullName = 'Full Name is required';
        } else if (!/^[a-zA-Z\s]+$/.test(fullName)) {
            errors.fullName = 'Name should only contain characters';
        }

        // Email validation
        if (!email.trim()) {
            errors.email = 'Email is required';
        } else {
            const emailRegex = /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/i;
            if (!emailRegex.test(email)) {
                errors.email = 'Invalid email address format';
            }
        }

        // Password validation
        if (!password) {
            errors.password = 'Password is required';
        } else if (password.length < 6) {
            errors.password = 'Password must be at least 6 characters';
        }

        // Age validation
        const ageInt = parseInt(age, 10);
        if (isNaN(ageInt) || ageInt <= 0 || ageInt >= 120) {
            errors.age = 'Valid age (1-119)';
        }

        // Height validation
        const heightInt = parseInt(height, 10);
        if (isNaN(heightInt) || heightInt <= 30 || heightInt >= 300) {
            errors.height = 'Valid height (30-300)';
        }

        // Contact validation
        if (!contactInfo) {
            errors.contactInfo = 'Required';
        } else if (contactInfo.length !== 10) {
            errors.contactInfo = 'Must be exactly 10 digits';
        } else if (!['6', '7', '8', '9'].includes(contactInfo[0])) {
            errors.contactInfo = 'Enter valid Indian number (6-9 start)';
        }

        // Address validation
        if (!address.trim()) {
            errors.address = 'Address is required';
        }

        // Role validation
        if (!formData.role) {
            errors.role = 'Please select your identity (PATIENT or DOCTOR)';
        }

        setFieldErrors(errors);
        return Object.keys(errors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        
        if (!validateForm()) {
            return;
        }

        setIsLoading(true);
        try {
            // Map keys to match backend's expected Schema (UserCreate)
            const signupPayload = {
                email: formData.email,
                name: formData.fullName,
                role: formData.role, // 'patient' or 'doctor'
                password: formData.password,
                age: parseInt(formData.age, 10),
                height: parseInt(formData.height, 10),
                gender: formData.gender,
                contact_number: formData.contactInfo,
                address: formData.address
            };
            
            await authService.signupSendOtp(signupPayload);
            setIsLoading(false);
            // Navigate to OTP verification page, passing email context
            navigate('/verify-otp', { state: { email: formData.email } });
        } catch (err) {
            setIsLoading(false);
            setError(err.response?.data?.error || err.response?.data?.detail || 'An error occurred during sign up.');
        }
    };

    const containerStyle = {
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        backgroundColor: '#ffffff',
        fontFamily: 'system-ui, -apple-system, sans-serif'
    };

    const inputStyle = (hasError) => ({
        width: '100%',
        height: '48px',
        padding: '0 16px 0 46px',
        border: hasError ? '2px solid #dc2626' : '1px solid #cbd5e1',
        borderRadius: '12px',
        fontSize: '0.95rem',
        fontWeight: '600',
        boxSizing: 'border-box',
        outline: 'none',
        color: '#0f172a'
    });

    const iconStyle = {
        position: 'absolute',
        left: '14px',
        top: '50%',
        transform: 'translateY(-50%)',
        color: '#94a3b8',
        pointerEvents: 'none'
    };

    const errorLabelStyle = {
        color: '#dc2626',
        fontSize: '0.75rem',
        fontWeight: '700',
        marginTop: '4px'
    };

    return (
        <div style={containerStyle}>
            {/* HERO PANEL (Split Screen) */}
            <div style={{ width: '40%', backgroundColor: '#134e4a', color: '#ffffff', padding: '4rem', display: 'flex', flexDirection: 'column', boxSizing: 'border-box' }}>
                <button
                    onClick={() => navigate('/login')}
                    style={{ background: 'none', border: 'none', color: '#ffffff', display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', marginBottom: '4rem', padding: 0, fontWeight: '700' }}
                >
                    <ChevronLeft size={20} /> BACK TO LOGIN
                </button>

                <h1 style={{ fontSize: '3rem', fontWeight: '900', lineHeight: '1.1', marginBottom: '1.5rem' }}>
                    Join the <br />
                    <span style={{ color: '#4db6ac' }}>Clinical Network.</span>
                </h1>
                <p style={{ fontSize: '1.1rem', color: '#9cc3c0', lineHeight: '1.6' }}>
                    Create your professional profile to start tracking peak flow metrics and receiving AI-driven titration insights.
                </p>

                <div style={{ marginTop: 'auto', borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '2rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <div style={{ padding: '0.5rem', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '0.5rem' }}>
                            <Wind size={20} />
                        </div>
                        <span style={{ fontWeight: '800', letterSpacing: '0.1em', fontSize: '0.8rem' }}>SECURE ENROLLMENT</span>
                    </div>
                </div>
            </div>

            {/* FORM PANEL */}
            <div style={{ width: '60%', overflowY: 'auto', padding: '4rem 2rem', display: 'flex', justifyContent: 'center', boxSizing: 'border-box' }}>
                <div style={{ width: '100%', maxWidth: '600px' }}>
                    <div style={{ marginBottom: '3rem' }}>
                        <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Create Account</h2>
                        <p style={{ color: '#64748b', marginTop: '4px', fontWeight: '500' }}>Please fill in your clinical details below</p>
                    </div>

                    <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>FULL NAME</label>
                                <div style={{ position: 'relative' }}>
                                    <User size={18} style={iconStyle} />
                                    <input name="fullName" value={formData.fullName} style={inputStyle(!!fieldErrors.fullName)} placeholder="John Doe" onChange={handleChange} required />
                                </div>
                                {fieldErrors.fullName && <div style={errorLabelStyle}>{fieldErrors.fullName}</div>}
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>EMAIL ADDRESS</label>
                                <div style={{ position: 'relative' }}>
                                    <Mail size={18} style={iconStyle} />
                                    <input name="email" value={formData.email} type="email" style={inputStyle(!!fieldErrors.email)} placeholder="john@example.com" onChange={handleChange} required />
                                </div>
                                {fieldErrors.email && <div style={errorLabelStyle}>{fieldErrors.email}</div>}
                            </div>
                        </div>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>PASSWORD</label>
                            <div style={{ position: 'relative' }}>
                                <Lock size={18} style={iconStyle} />
                                <input name="password" value={formData.password} type="password" style={inputStyle(!!fieldErrors.password)} placeholder="••••••••" onChange={handleChange} required />
                            </div>
                            {fieldErrors.password && <div style={errorLabelStyle}>{fieldErrors.password}</div>}
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1.5fr', gap: '1.5rem' }}>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>AGE</label>
                                <div style={{ position: 'relative' }}>
                                    <Calendar size={18} style={iconStyle} />
                                    <input name="age" value={formData.age} type="text" inputMode="numeric" style={inputStyle(!!fieldErrors.age)} placeholder="25" onChange={handleChange} required />
                                </div>
                                {fieldErrors.age && <div style={errorLabelStyle}>{fieldErrors.age}</div>}
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>HEIGHT (CM)</label>
                                <div style={{ position: 'relative' }}>
                                    <Ruler size={18} style={iconStyle} />
                                    <input name="height" value={formData.height} type="text" inputMode="numeric" style={inputStyle(!!fieldErrors.height)} placeholder="175" onChange={handleChange} required />
                                </div>
                                {fieldErrors.height && <div style={errorLabelStyle}>{fieldErrors.height}</div>}
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>GENDER</label>
                                <select
                                    name="gender"
                                    value={formData.gender}
                                    style={{ ...inputStyle(false), paddingLeft: '16px' }}
                                    onChange={handleChange}
                                >
                                    <option value="Male">Male</option>
                                    <option value="Female">Female</option>
                                    <option value="Other">Other</option>
                                </select>
                            </div>
                        </div>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>CONTACT NUMBER</label>
                            <div style={{ position: 'relative' }}>
                                <Phone size={18} style={iconStyle} />
                                <input name="contactInfo" value={formData.contactInfo} style={inputStyle(!!fieldErrors.contactInfo)} placeholder="10-digit mobile number" onChange={handleChange} required />
                            </div>
                            {fieldErrors.contactInfo && <div style={errorLabelStyle}>{fieldErrors.contactInfo}</div>}
                        </div>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>ADDRESS</label>
                            <div style={{ position: 'relative' }}>
                                <MapPin size={18} style={iconStyle} />
                                <input name="address" value={formData.address} style={inputStyle(!!fieldErrors.address)} placeholder="Current residential address" onChange={handleChange} required />
                            </div>
                            {fieldErrors.address && <div style={errorLabelStyle}>{fieldErrors.address}</div>}
                        </div>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', letterSpacing: '0.05em' }}>SELECT IDENTITY</label>
                            <div style={{ display: 'flex', backgroundColor: '#f1f5f9', padding: '4px', borderRadius: '12px', border: fieldErrors.role ? '2px solid #dc2626' : 'none' }}>
                                <button
                                    type="button"
                                    onClick={() => {
                                        setFormData({ ...formData, role: 'patient' });
                                        if (fieldErrors.role) setFieldErrors({ ...fieldErrors, role: '' });
                                    }}
                                    style={{ flex: 1, padding: '10px', borderRadius: '10px', border: 'none', fontWeight: '800', fontSize: '0.75rem', backgroundColor: formData.role === 'patient' ? '#ffffff' : 'transparent', color: formData.role === 'patient' ? '#134e4a' : '#94a3b8', cursor: 'pointer' }}
                                >
                                    PATIENT
                                </button>
                                <button
                                    type="button"
                                    onClick={() => {
                                        setFormData({ ...formData, role: 'doctor' });
                                        if (fieldErrors.role) setFieldErrors({ ...fieldErrors, role: '' });
                                    }}
                                    style={{ flex: 1, padding: '10px', borderRadius: '10px', border: 'none', fontWeight: '800', fontSize: '0.75rem', backgroundColor: formData.role === 'doctor' ? '#ffffff' : 'transparent', color: formData.role === 'doctor' ? '#134e4a' : '#94a3b8', cursor: 'pointer' }}
                                >
                                    DOCTOR
                                </button>
                            </div>
                            {fieldErrors.role && <div style={errorLabelStyle}>{fieldErrors.role}</div>}
                        </div>

                        {error && (
                            <div style={{ color: '#dc2626', fontSize: '0.85rem', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                <AlertCircle size={16} /> {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={isLoading}
                            style={{ width: '100%', height: '56px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '14px', fontWeight: '900', fontSize: '1rem', cursor: 'pointer', marginTop: '1rem' }}
                        >
                            {isLoading ? <Loader2 size={24} className="animate-spin" style={{ margin: 'auto' }} /> : 'REGISTER ACCOUNT'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Signup;
