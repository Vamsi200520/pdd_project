import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { doctorService } from '../../services/api';
import {
    ChevronLeft, Pill, Activity, History, ShieldCheck,
    AlertCircle, Plus, Loader2, Mail, Phone, Ruler,
    CheckCircle2, X, Wind, Calendar
} from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';

// ── Helpers matching backend snake_case keys ──────────────────────────────────
const g = (obj, ...keys) => {
    for (const k of keys) { if (obj?.[k] != null) return obj[k]; }
    return null;
};

const zoneConfig = {
    green: { bg: '#f0fdf4', color: '#16a34a', border: '#dcfce7' },
    yellow: { bg: '#fffbeb', color: '#d97706', border: '#fde68a' },
    red: { bg: '#fef2f2', color: '#dc2626', border: '#fee2e2' },
};
const getZoneStyle = (zone) => zoneConfig[(zone || '').toLowerCase()] || { bg: '#f8fafc', color: '#64748b', border: '#e2e8f0' };

const SymptomBar = ({ label, value }) => {
    if (value == null) return null;
    const pct = Math.round((value / 5) * 100);
    const barColor = value >= 4 ? '#ef4444' : value >= 3 ? '#f59e0b' : '#10b981';
    return (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.9rem 1.25rem', backgroundColor: '#f8fafc', borderRadius: '1rem', border: '1px solid #e2e8f0' }}>
            <span style={{ fontWeight: '700', color: '#475569', fontSize: '0.9rem' }}>{label}</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div style={{ width: '90px', height: '7px', borderRadius: '4px', backgroundColor: '#e2e8f0', overflow: 'hidden' }}>
                    <div style={{ width: `${pct}%`, height: '100%', backgroundColor: barColor, borderRadius: '4px', transition: 'width 0.4s ease' }} />
                </div>
                <span style={{ fontWeight: '900', fontSize: '0.9rem', color: '#0f172a', minWidth: '30px', textAlign: 'right' }}>{value}/5</span>
            </div>
        </div>
    );
};

// ── Main Component ────────────────────────────────────────────────────────────
const DoctorPatientDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [patient, setPatient] = useState(null);
    const [medications, setMedications] = useState([]);
    const [loading, setLoading] = useState(true);

    // Prescribe modal
    const [showPrescribe, setShowPrescribe] = useState(false);
    const [prescribeName, setPrescribeName] = useState('');
    const [prescribeDose, setPrescribeDose] = useState('');
    const [prescribeDesc, setPrescribeDesc] = useState('');
    const [prescribing, setPrescribing] = useState(false);
    const [prescribeSuccess, setPrescribeSuccess] = useState(false);

    const [trueLatestSymptom, setTrueLatestSymptom] = useState(null);

    const loadData = async () => {
        try {
            const [patients, meds, symps] = await Promise.all([
                doctorService.getPatients(),
                doctorService.getPatientMedications(id).catch(() => []),
                doctorService.getPatientSymptomRecords(id).catch(() => [])
            ]);
            const found = patients.find(p => String(p.id) === String(id));
            setPatient(found || null);
            setMedications(Array.isArray(meds) ? meds : []);

            if (Array.isArray(symps) && symps.length > 0) {
                const sorted = [...symps].sort((a, b) => new Date(b.recorded_at || b.onset_at || b.onsetAt) - new Date(a.recorded_at || a.onset_at || a.onsetAt));
                setTrueLatestSymptom(sorted[0]);
            }
        } catch (err) {
            console.error('Clinical sync failed:', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadData(); }, [id]);

    const handlePrescribe = async () => {
        if (!prescribeName.trim()) return;
        setPrescribing(true);
        try {
            await doctorService.prescribeMedication(id, {
                name: prescribeName,
                dose: prescribeDose || null,
                description: prescribeDesc || null,
            });
            setPrescribeSuccess(true);
            setTimeout(() => {
                setShowPrescribe(false);
                setPrescribeName(''); setPrescribeDose(''); setPrescribeDesc('');
                setPrescribeSuccess(false);
                loadData();
            }, 1500);
        } catch (err) {
            console.error('Prescribe failed:', err);
        } finally {
            setPrescribing(false);
        }
    };

    if (loading) return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
            <div style={{ width: '40px', height: '40px', border: '4px solid #e2e8f0', borderTopColor: '#134e4a', borderRadius: '50%' }} className="animate-spin" />
        </div>
    );

    if (!patient) return (
        <div style={{ textAlign: 'center', padding: '5rem', color: '#94a3b8' }}>
            <AlertCircle size={48} style={{ opacity: 0.3, marginBottom: '1rem' }} />
            <h2 style={{ fontWeight: '900', color: '#0f172a' }}>Patient Not Found</h2>
            <button onClick={() => navigate('/doctor/dashboard')} style={{ marginTop: '1.5rem', padding: '0.75rem 2rem', background: '#134e4a', color: '#fff', border: 'none', borderRadius: '12px', fontWeight: '800', cursor: 'pointer', fontSize: '0.95rem' }}>
                Return to Registry
            </button>
        </div>
    );

    // ── Read all fields using backend snake_case ──
    const displayName = g(patient, 'name') || patient.email || 'Unknown Patient';
    const email = g(patient, 'email') || '—';
    const contact = g(patient, 'contact_number') || '—';
    const age = g(patient, 'age');
    const height = g(patient, 'height');
    const gender = g(patient, 'gender') || '—';
    const baselineVal = g(patient, 'baseline')?.baseline_value;
    const pefr = patient.latest_pefr_record;
    const pefrValue = pefr?.pefr_value ?? pefr?.pefrValue;
    const zone = (pefr?.zone || '').toLowerCase();
    const zoneStyle = getZoneStyle(zone);
    const sym = trueLatestSymptom || patient.latest_symptom;

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}>

            {/* BACK */}
            <button onClick={() => navigate('/doctor/dashboard')}
                style={{ background: 'none', border: 'none', color: '#64748b', display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontWeight: '800', fontSize: '0.85rem', padding: 0, width: 'fit-content' }}>
                <ChevronLeft size={18} /> RETURN TO REGISTRY
            </button>

            {/* PATIENT HEADER */}
            <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2.5rem', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1.5rem' }}>
                <div style={{ display: 'flex', gap: '2rem', alignItems: 'center' }}>
                    <div style={{ width: '90px', height: '90px', backgroundColor: '#134e4a', color: '#ffffff', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2.25rem', fontWeight: '900', flexShrink: 0 }}>
                        {displayName.charAt(0).toUpperCase()}
                    </div>
                    <div>
                        <h1 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>{displayName}</h1>
                        <div style={{ display: 'flex', gap: '1.5rem', marginTop: '0.75rem', flexWrap: 'wrap' }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#64748b', fontWeight: '700', fontSize: '0.9rem' }}><Mail size={15} /> {email}</span>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#64748b', fontWeight: '700', fontSize: '0.9rem' }}><Phone size={15} /> {contact}</span>
                        </div>
                    </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '0.5rem' }}>
                    <div style={{ padding: '0.75rem 1.75rem', backgroundColor: zoneStyle.bg, color: zoneStyle.color, borderRadius: '15px', fontSize: '1rem', fontWeight: '900', textTransform: 'uppercase', border: `1px solid ${zoneStyle.border}` }}>
                        {zone || 'Unknown'} Zone
                    </div>
                    <div style={{ fontSize: '0.78rem', fontWeight: '800', color: '#94a3b8' }}>
                        {pefrValue ? `LATEST PEFR: ${pefrValue} L/min` : 'NO PEFR RECORDED'}
                    </div>
                </div>
            </div>

            {/* VITALS */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.25rem' }}>
                {[
                    { label: 'Age', value: age ? `${age} yr` : '—', Icon: Calendar },
                    { label: 'Height', value: height ? `${height} cm` : '—', Icon: Ruler },
                    { label: 'Gender', value: gender, Icon: ShieldCheck },
                    { label: 'Baseline', value: baselineVal ? `${baselineVal} L/min` : '—', Icon: Wind },
                ].map((item, i) => (
                    <div key={i} style={{ backgroundColor: '#ffffff', padding: '1.5rem', borderRadius: '1.5rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.5rem', textAlign: 'center' }}>
                        <item.Icon size={20} color="#134e4a" />
                        <div style={{ fontSize: '0.68rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.05em', textTransform: 'uppercase' }}>{item.label}</div>
                        <div style={{ fontSize: '1.25rem', fontWeight: '900', color: '#0f172a' }}>{item.value}</div>
                    </div>
                ))}
            </div>

            {/* PRESCRIPTIONS + SYMPTOMS */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>

                {/* PRESCRIPTIONS */}
                <div style={{ backgroundColor: '#0f172a', borderRadius: '2rem', padding: '2rem', color: '#ffffff', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <h3 style={{ fontSize: '1.15rem', fontWeight: '900', margin: 0 }}>Active Prescriptions</h3>
                        <Pill size={20} color="#4db6ac" />
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem', flex: 1 }}>
                        {medications.length > 0 ? medications.map(med => (
                            <div key={med.id} style={{ backgroundColor: 'rgba(255,255,255,0.06)', padding: '1.1rem 1.25rem', borderRadius: '1rem', border: '1px solid rgba(255,255,255,0.08)' }}>
                                <div style={{ fontWeight: '800', fontSize: '1rem', color: '#4db6ac' }}>{med.name}</div>
                                <div style={{ fontSize: '0.82rem', color: '#94a3b8', marginTop: '3px', fontWeight: '600' }}>
                                    {[med.dose, med.schedule].filter(Boolean).join(' • ') || 'As needed'}
                                </div>
                            </div>
                        )) : (
                            <div style={{ textAlign: 'center', padding: '2rem 1rem', color: '#475569' }}>
                                <Pill size={30} style={{ opacity: 0.25, marginBottom: '0.75rem' }} />
                                <p style={{ fontWeight: '700', margin: 0, fontSize: '0.9rem' }}>No active prescriptions</p>
                            </div>
                        )}
                    </div>
                    <button onClick={() => setShowPrescribe(true)}
                        style={{ width: '100%', height: '56px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '14px', fontWeight: '900', fontSize: '0.95rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', boxShadow: '0 6px 12px -3px rgba(19,78,74,0.45)', marginTop: 'auto' }}>
                        <Plus size={20} /> PRESCRIBE MEDICATION
                    </button>
                </div>

                {/* SYMPTOMS */}
                <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <h3 style={{ fontSize: '1.15rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Latest Symptom Report</h3>
                        <History size={20} color="#94a3b8" />
                    </div>

                    {sym ? (
                        <>
                            <SymptomBar label="Wheezing" value={sym.wheeze_rating ?? sym.wheezeRating} />
                            <SymptomBar label="Cough" value={sym.cough_rating ?? sym.coughRating} />
                            <SymptomBar label="Shortness of Breath" value={sym.dyspnea_rating ?? sym.dyspneaRating} />
                            <SymptomBar label="Chest Tightness" value={sym.chest_tightness_rating ?? sym.chestTightnessRating} />
                            <SymptomBar label="Night Symptoms" value={sym.night_symptoms_rating ?? sym.nightSymptomsRating} />
                            <SymptomBar label="Activity Limit" value={sym.activity_limitation_rating ?? sym.activityLimitationRating} />

                            {(sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs) != null && (
                                <div style={{ padding: '0.9rem 1.25rem', borderRadius: '1rem', backgroundColor: (sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs) >= 8 ? '#fef2f2' : '#f0fdf4', border: `1px solid ${(sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs) >= 8 ? '#fee2e2' : '#dcfce7'}` }}>
                                    <span style={{ fontWeight: '800', color: (sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs) >= 8 ? '#dc2626' : '#16a34a', fontSize: '0.9rem' }}>
                                        💨 Rescue Inhaler: {sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs} puffs
                                        {(sym.rescue_inhaler_puffs ?? sym.rescueInhalerPuffs) >= 8 && ' — ⚠️ High Usage'}
                                    </span>
                                </div>
                            )}

                            <p style={{ fontSize: '0.75rem', fontWeight: '700', color: '#94a3b8', margin: '0.5rem 0 0 0' }}>
                                Reported: {new Date(sym.recorded_at || sym.recordedAt || sym.onset_at || sym.onsetAt || Date.now()).toLocaleString()}
                            </p>
                        </>
                    ) : (
                        <div style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>
                            <Activity size={36} style={{ opacity: 0.2, marginBottom: '1rem' }} />
                            <p style={{ fontWeight: '700', margin: 0 }}>No symptom report yet</p>
                        </div>
                    )}
                </div>
            </div>

            {/* PRESCRIBE MODAL */}
            <AnimatePresence>
                {showPrescribe && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                        style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(15,23,42,0.85)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}
                        onClick={e => { if (e.target === e.currentTarget) setShowPrescribe(false); }}>
                        <motion.div initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9 }}
                            style={{ backgroundColor: '#134e4a', borderRadius: '2.5rem', padding: '3rem', width: '100%', maxWidth: '500px', color: '#ffffff', position: 'relative' }}>
                            <button onClick={() => setShowPrescribe(false)}
                                style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'rgba(255,255,255,0.1)', border: 'none', color: '#fff', borderRadius: '50%', width: '36px', height: '36px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <X size={18} />
                            </button>
                            <h2 style={{ fontSize: '1.75rem', fontWeight: '900', margin: '0 0 0.4rem 0' }}>Prescribe</h2>
                            <p style={{ color: '#b2dfdb', fontSize: '0.95rem', marginBottom: '2rem' }}>For: {displayName}</p>

                            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.1rem' }}>
                                {[
                                    { label: 'MEDICATION NAME *', val: prescribeName, set: setPrescribeName, ph: 'e.g. Salbutamol Inhaler' },
                                    { label: 'DOSAGE', val: prescribeDose, set: setPrescribeDose, ph: 'e.g. 2 puffs twice daily' },
                                ].map(f => (
                                    <div key={f.label}>
                                        <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#4db6ac', display: 'block', marginBottom: '0.4rem', letterSpacing: '0.1em' }}>{f.label}</label>
                                        <input value={f.val} onChange={e => f.set(e.target.value)} placeholder={f.ph}
                                            style={{ width: '100%', padding: '0.9rem 1rem', borderRadius: '12px', border: 'none', backgroundColor: '#ffffff', color: '#0f172a', fontWeight: '700', fontSize: '0.95rem', outline: 'none', boxSizing: 'border-box' }} />
                                    </div>
                                ))}
                                <div>
                                    <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#4db6ac', display: 'block', marginBottom: '0.4rem', letterSpacing: '0.1em' }}>CLINICAL NOTES (optional)</label>
                                    <textarea value={prescribeDesc} onChange={e => setPrescribeDesc(e.target.value)} placeholder="Additional instructions..." rows={3}
                                        style={{ width: '100%', padding: '0.9rem 1rem', borderRadius: '12px', border: 'none', backgroundColor: '#ffffff', color: '#0f172a', fontWeight: '600', fontSize: '0.9rem', outline: 'none', resize: 'none', boxSizing: 'border-box' }} />
                                </div>
                                <button onClick={handlePrescribe} disabled={!prescribeName.trim() || prescribing}
                                    style={{ width: '100%', height: '58px', backgroundColor: prescribeSuccess ? '#10b981' : '#4db6ac', color: '#ffffff', border: 'none', borderRadius: '16px', fontWeight: '900', fontSize: '1rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', marginTop: '0.5rem', opacity: !prescribeName.trim() ? 0.5 : 1, transition: 'all 0.2s' }}>
                                    {prescribing ? <Loader2 size={22} className="animate-spin" /> : prescribeSuccess ? <><CheckCircle2 size={22} /> PRESCRIBED!</> : <><Pill size={22} /> CONFIRM PRESCRIPTION</>}
                                </button>
                            </div>
                        </motion.div>
                    </motion.div>
                )}
            </AnimatePresence>

            <div style={{ height: '4rem' }} />
        </div>
    );
};

export default DoctorPatientDetail;
