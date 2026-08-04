import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { patientService } from '../../services/api';
import {
    Wind, ClipboardList, ChevronRight, AlertCircle, CheckCircle2,
    Activity, History, TrendingUp, X
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Dashboard = () => {
    const navigate = useNavigate();
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [records, setRecords] = useState([]);
    const [symptoms, setSymptoms] = useState([]);

    // PEFR Input Modal State
    const [showPefrInput, setShowPefrInput] = useState(false);
    const [pefrVal, setPefrVal] = useState('');
    const [isSubmittingPefr, setIsSubmittingPefr] = useState(false);

    const fetchDashboardData = async () => {
        try {
            const [profile, pefrRecords, symptomRecords, dismissedIds, dismissedPefrIds] = await Promise.all([
                patientService.getProfile(),
                patientService.getPefrRecords(),
                patientService.getSymptomRecords(),
                patientService.getDismissedSymptomIds(),
                patientService.getDismissedPefrIds()
            ]);
            setStats(profile);

            // Backend returns array, sort descending by date so index 0 is newest
            const sortedPefr = Array.isArray(pefrRecords) ? [...pefrRecords].sort((a, b) => new Date(b.recorded_at || b.recordedAt) - new Date(a.recorded_at || a.recordedAt)) : [];
            const sortedSymp = Array.isArray(symptomRecords) ? [...symptomRecords].sort((a, b) => new Date(b.recorded_at || b.onset_at || b.onsetAt) - new Date(a.recorded_at || a.onset_at || a.onsetAt)) : [];

            // Filter out any dismissed symptom IDs to sync across devices
            const dismissedSet = new Set(dismissedIds);
            const filteredSymp = sortedSymp.filter(s => !dismissedSet.has(s.id));

            // Filter out any dismissed PEFR record IDs to sync across devices
            const dismissedPefrSet = new Set(dismissedPefrIds);
            const filteredPefr = sortedPefr.filter(r => !dismissedPefrSet.has(r.id));

            setRecords(filteredPefr);
            setSymptoms(filteredSymp.slice(0, 5));
        } catch (err) {
            setError('Failed to sync clinical data');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { fetchDashboardData(); }, []);

    const handleDeleteSymptom = async (id) => {
        // Optimistically remove from UI
        setSymptoms(prev => prev.filter(s => s.id !== id));
        try {
            await patientService.dismissSymptomId(id);
        } catch (err) {
            console.error('Failed to dismiss symptom:', err);
        }
    };

    const handleRecordPefr = async () => {
        if (!pefrVal || isNaN(pefrVal)) return;
        setIsSubmittingPefr(true);
        try {
            await patientService.recordPefr(parseInt(pefrVal, 10));
            setShowPefrInput(false);
            setPefrVal('');
            fetchDashboardData();
        } catch (err) {
            console.error('Failed to record PEFR:', err);
        } finally {
            setIsSubmittingPefr(false);
        }
    };

    const getZoneInfo = (value, baseline) => {
        if (!value || !baseline) return { label: 'Incomplete Data', color: '#94a3b8', guidance: 'Record today\'s session to see status' };
        const percent = (value / baseline) * 100;
        if (percent >= 80) return { label: 'Green Zone', color: '#10b981', guidance: 'Optimal Management. Continue regular plan.' };
        if (percent >= 50) return { label: 'Yellow Zone', color: '#f59e0b', guidance: 'Caution. Use reliever inhaler as prescribed.' };
        return { label: 'Red Zone', color: '#ef4444', guidance: 'Emergency Risk! Seek medical attention now.' };
    };

    if (loading) return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
            <div className="animate-spin" style={{ width: '40px', height: '40px', border: '4px solid #e2e8f0', borderTopColor: '#134e4a', borderRadius: '50%' }}></div>
        </div>
    );

    // After sorting, records[0] is the true latest record
    const latestPefr = records[0]?.pefr_value || records[0]?.pefrValue || 0;
    const baseline = stats?.baseline?.baseline_value || stats?.baseline?.baselineValue || 0;
    const zoneInfo = getZoneInfo(latestPefr, baseline);

    return (
        <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2.5rem' }}>
            {/* LEFT COLUMN: PRIMARY CLINICAL DATA */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                <div style={{ marginBottom: '1rem' }}>
                    <h1 style={{ fontSize: '2.25rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Clinical Workspace</h1>
                    <p style={{ color: '#64748b', fontWeight: '500', margin: '4px 0 0 0' }}>Welcome back, {stats?.name || stats?.fullName}. Your clinical markers are synced.</p>
                </div>

                {/* TODAY'S ZONE CARD */}
                <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
                    style={{ backgroundColor: zoneInfo.color, borderRadius: '2rem', padding: '2.5rem', color: '#ffffff', boxShadow: `0 20px 25px -5px ${zoneInfo.color}40` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                        <div>
                            <div style={{ fontSize: '0.85rem', fontWeight: '900', letterSpacing: '0.15em', textTransform: 'uppercase', opacity: 0.9 }}>TODAY'S LUNG STATUS</div>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: '900', margin: '4px 0' }}>{zoneInfo.label}</h2>
                        </div>
                        <div style={{ backgroundColor: 'rgba(255,255,255,0.2)', padding: '0.5rem 1rem', borderRadius: '12px', fontWeight: '900', fontSize: '0.9rem' }}>
                            {latestPefr && baseline ? `${Math.round((latestPefr / baseline) * 100)}% OF BASELINE` : 'NO DATA'}
                        </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'baseline', gap: '1rem', margin: '1.5rem 0' }}>
                        <span style={{ fontSize: '5rem', fontWeight: '900', lineHeight: 1 }}>{latestPefr || '---'}</span>
                        <span style={{ fontSize: '1.5rem', fontWeight: '700', opacity: 0.8 }}>L/min</span>
                    </div>

                    <div style={{ borderTop: '1px solid rgba(255,255,255,0.2)', paddingTop: '1.5rem', display: 'flex', gap: '1rem', alignItems: 'center' }}>
                        <div style={{ width: '40px', height: '40px', backgroundColor: 'rgba(255,255,255,0.2)', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Activity size={20} />
                        </div>
                        <p style={{ fontSize: '1.05rem', fontWeight: '600', margin: 0 }}>{zoneInfo.guidance}</p>
                    </div>
                </motion.div>

                {/* ACTION CARDS */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                    <div onClick={() => setShowPefrInput(true)}
                        style={{ backgroundColor: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '1.5rem', padding: '1.75rem', cursor: 'pointer', transition: 'all 0.2s', display: 'flex', flexDirection: 'column', gap: '1rem' }}
                        onMouseEnter={e => e.currentTarget.style.borderColor = '#134e4a'} onMouseLeave={e => e.currentTarget.style.borderColor = '#e2e8f0'}>
                        <div style={{ width: '50px', height: '50px', backgroundColor: '#eef2ff', color: '#134e4a', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Wind size={24} />
                        </div>
                        <div>
                            <div style={{ fontWeight: '900', fontSize: '1.1rem', color: '#0f172a' }}>Record PEFR</div>
                            <div style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: '500' }}>Save manual lung metrics</div>
                        </div>
                        <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#134e4a', fontWeight: '800', fontSize: '0.8rem' }}>
                            INPUT VALUE <ChevronRight size={14} />
                        </div>
                    </div>
                    <div onClick={() => navigate('/patient/symptom')}
                        style={{ backgroundColor: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '1.5rem', padding: '1.75rem', cursor: 'pointer', transition: 'all 0.2s', display: 'flex', flexDirection: 'column', gap: '1rem' }}
                        onMouseEnter={e => e.currentTarget.style.borderColor = '#4db6ac'} onMouseLeave={e => e.currentTarget.style.borderColor = '#e2e8f0'}>
                        <div style={{ width: '50px', height: '50px', backgroundColor: '#f0fdf4', color: '#059669', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <ClipboardList size={24} />
                        </div>
                        <div>
                            <div style={{ fontWeight: '900', fontSize: '1.1rem', color: '#0f172a' }}>Track Symptoms</div>
                            <div style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: '500' }}>Rate clinical severity</div>
                        </div>
                        <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#059669', fontWeight: '800', fontSize: '0.8rem' }}>
                            OPEN TRACKER <ChevronRight size={14} />
                        </div>
                    </div>
                </div>
            </div>

            {/* RIGHT COLUMN: RECENT OBSERVATIONS & TRENDS */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2rem', border: '1px solid #e2e8f0' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                        <h3 style={{ fontSize: '1.1rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Recent Observations</h3>
                        <History size={20} color="#94a3b8" />
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {symptoms.length > 0 ? symptoms.map((s, idx) => {
                            const wheeze = s.wheeze_rating ?? s.wheezeRating ?? 0;
                            const cough = s.cough_rating ?? s.coughRating ?? 0;
                            return (
                                <div key={s.id || idx} style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '1rem', backgroundColor: '#f8fafc', borderRadius: '1rem' }}>
                                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: (wheeze > 3 || cough > 3) ? '#ef4444' : '#10b981' }}></div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ fontSize: '0.9rem', fontWeight: '700', color: '#0f172a' }}>
                                            Wheeze: {wheeze}/5 · Cough: {cough}/5
                                        </div>
                                        <div style={{ fontSize: '0.75rem', fontWeight: '600', color: '#94a3b8' }}>
                                            {new Date(s.recorded_at || s.onset_at || s.onsetAt).toLocaleDateString()}
                                        </div>
                                    </div>
                                </div>
                            );
                        }) : (
                            <div style={{ textAlign: 'center', padding: '3rem 1rem', color: '#94a3b8' }}>
                                <AlertCircle size={32} style={{ marginBottom: '1rem', opacity: 0.5 }} />
                                <div style={{ fontSize: '0.9rem', fontWeight: '600' }}>No recent symptoms recorded</div>
                            </div>
                        )}
                    </div>
                </div>

                <div style={{ backgroundColor: '#0f172a', borderRadius: '2rem', padding: '2rem', color: '#ffffff', overflow: 'hidden', position: 'relative' }}>
                    <div style={{ position: 'relative', zIndex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
                            <TrendingUp size={20} color="#4db6ac" />
                            <span style={{ fontSize: '0.8rem', fontWeight: '900', letterSpacing: '0.1em' }}>PRECISION TRENDS</span>
                        </div>
                        <h4 style={{ fontSize: '1.5rem', fontWeight: '800', margin: 0 }}>Stability Report</h4>
                        <p style={{ color: '#94a3b8', fontSize: '0.9rem', fontWeight: '500', marginTop: '4px' }}>AI analyzing last 7 days...</p>
                        <div style={{ marginTop: '2rem', height: '60px', display: 'flex', alignItems: 'flex-end', gap: '4px' }}>
                            {[40, 70, 45, 90, 65, 80, 50].map((h, i) => (
                                <div key={i} style={{ flex: 1, height: `${h}%`, backgroundColor: i === 3 ? '#4db6ac' : 'rgba(255,255,255,0.1)', borderRadius: '4px' }}></div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>

            {/* PEFR INPUT MODAL */}
            <AnimatePresence>
                {showPefrInput && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                        style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(15,23,42,0.85)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}
                        onClick={e => { if (e.target === e.currentTarget) setShowPefrInput(false); }}>
                        <motion.div initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9 }}
                            style={{ backgroundColor: '#134e4a', borderRadius: '2.5rem', padding: '3rem', width: '100%', maxWidth: '400px', color: '#ffffff', position: 'relative', textAlign: 'center' }}>
                            <button onClick={() => setShowPefrInput(false)}
                                style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'rgba(255,255,255,0.1)', border: 'none', color: '#fff', borderRadius: '50%', width: '36px', height: '36px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <X size={18} />
                            </button>
                            <div style={{ width: '64px', height: '64px', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1.5rem', color: '#4db6ac' }}>
                                <Wind size={32} />
                            </div>
                            <h2 style={{ fontSize: '1.75rem', fontWeight: '900', margin: '0 0 0.5rem 0' }}>Record PEFR</h2>
                            <p style={{ color: '#b2dfdb', fontSize: '0.95rem', marginBottom: '2rem' }}>Enter your peak flow reading in L/min</p>
                            <input
                                type="number" value={pefrVal} onChange={e => setPefrVal(e.target.value)}
                                placeholder="0" autoFocus
                                style={{ width: '100%', padding: '1rem', borderRadius: '1rem', border: 'none', backgroundColor: 'rgba(255,255,255,0.1)', color: '#ffffff', fontSize: '3rem', fontWeight: '900', textAlign: 'center', outline: 'none', marginBottom: '1.5rem' }}
                            />
                            <button onClick={handleRecordPefr} disabled={!pefrVal || isSubmittingPefr}
                                style={{ width: '100%', height: '56px', backgroundColor: '#4db6ac', color: '#ffffff', border: 'none', borderRadius: '14px', fontWeight: '900', fontSize: '1rem', cursor: 'pointer', transition: 'all 0.2s', opacity: !pefrVal ? 0.5 : 1 }}>
                                {isSubmittingPefr ? 'SAVING...' : 'SAVE RECORD'}
                            </button>
                        </motion.div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default Dashboard;
