import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { patientService } from '../../services/api';
import {
    Activity, Calendar, TrendingUp, History,
    AlertCircle, Download, CheckCircle2, Wind, X
} from 'lucide-react';
import PEFRChart from '../../components/ui/PEFRChart';
import { motion } from 'framer-motion';

const GraphPage = () => {
    const navigate = useNavigate();
    const [days, setDays] = useState(7);
    const [pefrRecords, setPefrRecords] = useState([]);
    const [symptoms, setSymptoms] = useState([]);
    const [baseline, setBaseline] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            try {
                const [profile, pefrData, symptomData, dismissedPefrIds, dismissedSymptomIds] = await Promise.all([
                    patientService.getProfile(),
                    patientService.getPefrRecords(),
                    patientService.getSymptomRecords(),
                    patientService.getDismissedPefrIds(),
                    patientService.getDismissedSymptomIds()
                ]);
                // Backend: baseline.baseline_value
                setBaseline(profile?.baseline?.baseline_value || null);
                
                const pefrSet = new Set(dismissedPefrIds);
                const symSet = new Set(dismissedSymptomIds);
                
                setPefrRecords(Array.isArray(pefrData) ? pefrData.filter(r => !pefrSet.has(r.id)) : []);
                setSymptoms(Array.isArray(symptomData) ? symptomData.filter(s => !symSet.has(s.id)) : []);
            } catch (err) {
                console.error('Failed to load clinical history', err);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, []);

    const handleDeletePefr = async (id) => {
        // Optimistically remove from state
        setPefrRecords(prev => prev.filter(r => r.id !== id));
        try {
            await patientService.dismissPefrId(id);
        } catch (err) {
            console.error('Failed to dismiss PEFR record:', err);
        }
    };

    // Compute stats from pefrRecords
    const computeStats = () => {
        if (pefrRecords.length === 0) return { highest: '—', lowest: '—', mean: '—', variability: '—' };
        const vals = pefrRecords.map(r => r.pefr_value ?? r.pefrValue).filter(Boolean);
        const max = Math.max(...vals);
        const min = Math.min(...vals);
        const mean = Math.round(vals.reduce((a, b) => a + b, 0) / vals.length);
        const variability = vals.length > 1 ? `${Math.round(((max - min) / mean) * 100)}%` : '—';
        return { highest: max, lowest: min, mean, variability };
    };

    const stats = computeStats();

    // Export report function matching iOS clinical CSV exports
    const exportReport = () => {
        let csvContent = "data:text/csv;charset=utf-8,";
        csvContent += "Type,Value,Date\n";

        pefrRecords.forEach(r => {
            const date = new Date(r.recorded_at || r.recordedAt).toLocaleString();
            csvContent += `PEFR,${r.pefr_value || r.pefrValue},"${date}"\n`;
        });

        symptoms.forEach(s => {
            const date = new Date(s.recorded_at || s.onsetAt || s.onset_at).toLocaleString();
            const wheeze = s.wheeze_rating || s.wheezeRating || 0;
            const cough = s.cough_rating || s.coughRating || 0;
            csvContent += `Symptom,Wheeze:${wheeze} Cough:${cough},"${date}"\n`;
        });

        const encodedUri = encodeURI(csvContent);
        const link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", `clinical_report_${new Date().toISOString().split('T')[0]}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}>

            {/* HEADER */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ fontSize: '2.5rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>PPC Clinical Chart</h1>
                    <p style={{ color: '#64748b', fontSize: '1rem', fontWeight: '500', marginTop: '4px' }}>
                        Baseline: {baseline ? `${baseline} L/min` : 'Not set'} · {pefrRecords.length} records
                    </p>
                </div>
                <div style={{ display: 'flex', backgroundColor: '#ffffff', border: '1px solid #e2e8f0', padding: '6px', borderRadius: '14px' }}>
                    {[{ label: 'WEEKLY', val: 7 }, { label: 'MONTHLY', val: 30 }].map(b => (
                        <button key={b.val} onClick={() => setDays(b.val)}
                            style={{ padding: '0.65rem 1.5rem', borderRadius: '10px', border: 'none', fontWeight: '800', fontSize: '0.82rem', backgroundColor: days === b.val ? '#134e4a' : 'transparent', color: days === b.val ? '#ffffff' : '#64748b', cursor: 'pointer', transition: 'all 0.2s' }}>
                            {b.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* STAT CARDS ROW */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.25rem' }}>
                {[
                    { label: 'Highest PEFR', value: stats.highest, unit: 'L/min', color: '#10b981', Icon: TrendingUp },
                    { label: 'Lowest PEFR', value: stats.lowest, unit: 'L/min', color: '#f59e0b', Icon: Activity },
                    { label: 'Mean PEFR', value: stats.mean, unit: 'L/min', color: '#134e4a', Icon: Wind },
                    { label: 'Variability', value: stats.variability, unit: '', color: '#8b5cf6', Icon: CheckCircle2 },
                ].map((s, i) => (
                    <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}
                        style={{ backgroundColor: '#ffffff', padding: '1.5rem', borderRadius: '1.5rem', border: '1px solid #e2e8f0' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: s.color, marginBottom: '0.75rem' }}>
                            <s.Icon size={16} />
                            <span style={{ fontSize: '0.7rem', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{s.label}</span>
                        </div>
                        <div style={{ fontSize: '1.75rem', fontWeight: '900', color: '#0f172a' }}>
                            {s.value} <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: '700' }}>{s.unit}</span>
                        </div>
                    </motion.div>
                ))}
            </div>

            {/* CHART + SYMPTOM TIMELINE */}
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem' }}>

                {/* CHART */}
                <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2.5rem', border: '1px solid #e2e8f0', height: '480px', display: 'flex', flexDirection: 'column' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                            <div style={{ width: '40px', height: '40px', backgroundColor: '#eef2ff', color: '#134e4a', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Activity size={20} />
                            </div>
                            <div>
                                <div style={{ fontWeight: '900', color: '#0f172a', fontSize: '1rem' }}>PEFR Dynamics</div>
                                <div style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: '700' }}>
                                    {days === 7 ? 'Last 7 days' : 'Last 30 days'} · Dots coloured by zone
                                </div>
                            </div>
                        </div>
                        <button onClick={exportReport} style={{ backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', padding: '0.65rem 1rem', borderRadius: '10px', fontWeight: '800', fontSize: '0.78rem', color: '#134e4a', display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer' }}>
                            <Download size={14} /> EXPORT
                        </button>
                    </div>
                    <div style={{ flex: 1 }}>
                        <PEFRChart days={days} />
                    </div>
                </div>

                {/* SYMPTOM TIMELINE */}
                <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', height: '480px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <h3 style={{ fontSize: '1.1rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Symptom Timeline</h3>
                        <History size={18} color="#94a3b8" />
                    </div>

                    <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                        {symptoms.length > 0 ? symptoms.slice(0, 12).map((s, idx) => {
                            // Backend fields: wheeze_rating, cough_rating, rescue_inhaler_puffs, recorded_at
                            const wheeze = s.wheeze_rating ?? s.wheezeRating ?? 0;
                            const cough = s.cough_rating ?? s.coughRating ?? 0;
                            const puffs = s.rescue_inhaler_puffs ?? s.rescueInhalerPuffs ?? 0;
                            const date = new Date(s.recorded_at || s.onsetAt || Date.now());
                            const isBad = wheeze >= 4 || cough >= 4 || puffs >= 8;
                            return (
                                <div key={idx} style={{ padding: '1rem 1.25rem', backgroundColor: '#f8fafc', borderRadius: '1rem', border: `1px solid ${isBad ? '#fee2e2' : '#e2e8f0'}` }}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                                        <span style={{ fontSize: '0.72rem', fontWeight: '900', color: isBad ? '#ef4444' : '#4db6ac', textTransform: 'uppercase' }}>
                                            {isBad ? '⚠ ALERT' : 'RECORD'}
                                        </span>
                                        <span style={{ fontSize: '0.7rem', fontWeight: '700', color: '#94a3b8' }}>
                                            {date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                                        </span>
                                    </div>
                                    <div style={{ fontSize: '0.9rem', fontWeight: '800', color: '#0f172a' }}>
                                        Wheeze {wheeze}/5 · Cough {cough}/5
                                    </div>
                                    {puffs > 0 && (
                                        <div style={{ fontSize: '0.78rem', fontWeight: '700', color: puffs >= 8 ? '#ef4444' : '#64748b', marginTop: '3px' }}>
                                            💨 {puffs} rescue puffs
                                        </div>
                                    )}
                                </div>
                            );
                        }) : (
                            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', color: '#94a3b8' }}>
                                <AlertCircle size={32} style={{ opacity: 0.2, marginBottom: '0.75rem' }} />
                                <p style={{ fontWeight: '700', margin: 0, fontSize: '0.9rem' }}>No symptom records yet</p>
                                <button onClick={() => navigate('/patient/symptom')}
                                    style={{ marginTop: '1rem', padding: '0.5rem 1.25rem', backgroundColor: '#134e4a', color: '#fff', border: 'none', borderRadius: '10px', fontWeight: '800', fontSize: '0.82rem', cursor: 'pointer' }}>
                                    RECORD NOW
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* PEFR LOG HISTORY */}
            <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>PEFR Log History</h3>
                    <Activity size={20} color="#94a3b8" />
                </div>
                
                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                        <thead>
                            <tr style={{ borderBottom: '2px solid #f1f5f9', color: '#94a3b8', fontSize: '0.8rem', fontWeight: '900', letterSpacing: '0.1em' }}>
                                <th style={{ padding: '1rem' }}>DATE / TIME</th>
                                <th style={{ padding: '1rem' }}>PEFR VALUE</th>
                                <th style={{ padding: '1rem' }}>STATUS ZONE</th>
                                <th style={{ padding: '1rem', textAlign: 'right' }}>ACTION</th>
                            </tr>
                        </thead>
                        <tbody>
                            {pefrRecords.length > 0 ? [...pefrRecords].sort((a, b) => new Date(b.recorded_at || b.recordedAt) - new Date(a.recorded_at || a.recordedAt)).map((r, idx) => {
                                const val = r.pefr_value ?? r.pefrValue ?? 0;
                                const date = new Date(r.recorded_at || r.recordedAt || Date.now());
                                const z = (r.zone || '').toLowerCase();
                                const zoneColor = z === 'red' ? '#ef4444' : z === 'yellow' ? '#f59e0b' : '#10b981';
                                return (
                                    <tr key={r.id || idx} style={{ borderBottom: '1px solid #f1f5f9', fontSize: '0.92rem', fontWeight: '700', color: '#334155' }}>
                                        <td style={{ padding: '1rem' }}>
                                            {date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                                        </td>
                                        <td style={{ padding: '1rem', fontSize: '1.1rem', fontWeight: '900', color: '#0f172a' }}>
                                            {val} <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: '700' }}>L/min</span>
                                        </td>
                                        <td style={{ padding: '1rem' }}>
                                            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.4rem', color: zoneColor }}>
                                                <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: zoneColor }}></span>
                                                {z.toUpperCase()} ZONE
                                            </span>
                                        </td>
                                        <td style={{ padding: '1rem', textAlign: 'right' }}>
                                            <button
                                                onClick={() => handleDeletePefr(r.id)}
                                                style={{ background: 'none', border: 'none', color: '#cbd5e1', cursor: 'pointer', padding: '6px', borderRadius: '50%', transition: 'all 0.2s', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}
                                                onMouseEnter={e => { e.currentTarget.style.color = '#ef4444'; e.currentTarget.style.backgroundColor = '#fef2f2'; }}
                                                onMouseLeave={e => { e.currentTarget.style.color = '#cbd5e1'; e.currentTarget.style.backgroundColor = 'transparent'; }}
                                            >
                                                <X size={16} />
                                            </button>
                                        </td>
                                    </tr>
                                );
                            }) : (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8', fontWeight: '600' }}>
                                        No PEFR records found.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div style={{ height: '3rem' }} />
        </div>
    );
};

export default GraphPage;
