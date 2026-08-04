import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { doctorService } from '../../services/api';
import {
    Users,
    AlertCircle,
    CheckCircle2,
    Search,
    ChevronRight,
    Stethoscope,
    Activity,
    Mail,
    Wind
} from 'lucide-react';
import { motion } from 'framer-motion';

// Helper: read zone from backend key latest_pefr_record
const getZone = (p) => (p.latest_pefr_record?.zone || '').toLowerCase();
const getPefr = (p) => p.latest_pefr_record?.pefr_value;

const zoneConfig = {
    green: { bg: '#f0fdf4', text: '#16a34a', border: '#dcfce7', label: 'Green Zone' },
    yellow: { bg: '#fffbeb', text: '#d97706', border: '#fde68a', label: 'Yellow Zone' },
    red: { bg: '#fef2f2', text: '#dc2626', border: '#fee2e2', label: 'Red Zone' },
};
const getZoneStyle = (zone) => zoneConfig[zone] || { bg: '#f8fafc', text: '#94a3b8', border: '#e2e8f0', label: 'No Data' };

const DoctorDashboard = () => {
    const navigate = useNavigate();
    const [patients, setPatients] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [zoneFilter, setZoneFilter] = useState('All');

    useEffect(() => {
        doctorService.getPatients()
            .then(data => setPatients(Array.isArray(data) ? data : []))
            .catch(err => console.error('Failed to fetch patients', err))
            .finally(() => setLoading(false));
    }, []);

    const filtered = patients.filter(p => {
        const name = (p.name || p.email || '').toLowerCase();
        const matchSearch = name.includes(searchTerm.toLowerCase()) ||
            (p.email || '').toLowerCase().includes(searchTerm.toLowerCase());
        const matchZone = zoneFilter === 'All' || getZone(p) === zoneFilter.toLowerCase();
        return matchSearch && matchZone;
    });

    const stats = {
        total: patients.length,
        green: patients.filter(p => getZone(p) === 'green').length,
        yellow: patients.filter(p => getZone(p) === 'yellow').length,
        red: patients.filter(p => getZone(p) === 'red').length,
    };

    if (loading) return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
            <div style={{ width: '40px', height: '40px', border: '4px solid #e2e8f0', borderTopColor: '#134e4a', borderRadius: '50%' }} className="animate-spin" />
        </div>
    );

    return (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>

            {/* HEADER */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                <div>
                    <h1 style={{ fontSize: '2.5rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Doctor Workspace</h1>
                    <p style={{ color: '#64748b', fontSize: '1rem', fontWeight: '500', marginTop: '4px' }}>Real-time pulmonary monitoring for linked patients.</p>
                </div>
                <div style={{ backgroundColor: '#ffffff', padding: '0.75rem 1.25rem', borderRadius: '12px', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Stethoscope size={20} color="#134e4a" />
                    <span style={{ fontWeight: '800', fontSize: '0.85rem', color: '#134e4a' }}>CERTIFIED PORTAL</span>
                </div>
            </div>

            {/* STATS — 4 equal columns, no overlap */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.25rem' }}>
                {[
                    { label: 'Total Patients', value: stats.total, color: '#0f172a', Icon: Users, bg: '#ffffff' },
                    { label: 'Stable', value: stats.green, color: '#10b981', Icon: CheckCircle2, bg: '#f0fdf4' },
                    { label: 'Monitoring', value: stats.yellow, color: '#d97706', Icon: Activity, bg: '#fffbeb' },
                    { label: 'Critical', value: stats.red, color: '#dc2626', Icon: AlertCircle, bg: '#fef2f2' },
                ].map((s, i) => (
                    <motion.div key={i}
                        initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}
                        style={{ backgroundColor: s.bg, borderRadius: '1.5rem', padding: '1.75rem', border: '1px solid #e2e8f0' }}
                    >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', color: s.color, marginBottom: '0.75rem' }}>
                            <s.Icon size={18} />
                            <span style={{ fontSize: '0.75rem', fontWeight: '900', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{s.label}</span>
                        </div>
                        <div style={{ fontSize: '2.75rem', fontWeight: '900', color: s.color, lineHeight: 1 }}>{s.value}</div>
                    </motion.div>
                ))}
            </div>

            {/* SEARCH + FILTER BAR */}
            <div style={{ display: 'flex', gap: '1rem', backgroundColor: '#ffffff', padding: '1rem', borderRadius: '1.5rem', border: '1px solid #e2e8f0' }}>
                <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center' }}>
                    <Search size={18} color="#94a3b8" style={{ position: 'absolute', left: '1rem', pointerEvents: 'none' }} />
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        value={searchTerm}
                        onChange={e => setSearchTerm(e.target.value)}
                        style={{ width: '100%', height: '48px', paddingLeft: '3rem', borderRadius: '10px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc', fontSize: '0.95rem', fontWeight: '600', outline: 'none', color: '#0f172a', boxSizing: 'border-box' }}
                    />
                </div>
                <div style={{ display: 'flex', border: '1px solid #e2e8f0', borderRadius: '10px', overflow: 'hidden' }}>
                    {['All', 'Green', 'Yellow', 'Red'].map(z => (
                        <button key={z} onClick={() => setZoneFilter(z)}
                            style={{ padding: '0 1.25rem', height: '48px', border: 'none', borderRight: '1px solid #e2e8f0', backgroundColor: zoneFilter === z ? '#134e4a' : '#ffffff', color: zoneFilter === z ? '#ffffff' : '#64748b', fontWeight: '800', fontSize: '0.8rem', cursor: 'pointer', transition: 'all 0.15s' }}
                        >{z.toUpperCase()}</button>
                    ))}
                </div>
            </div>

            {/* PATIENT ROSTER TABLE */}
            <div style={{ backgroundColor: '#ffffff', borderRadius: '2rem', border: '1px solid #e2e8f0', overflow: 'hidden' }}>
                {/* Table Header */}
                <div style={{ padding: '1.25rem 2rem', backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0', display: 'grid', gridTemplateColumns: '56px 1.8fr 1fr 1fr 140px', gap: '1.5rem', alignItems: 'center' }}>
                    {['', 'Patient', 'Latest PEFR', 'Zone Status', 'Actions'].map((h, i) => (
                        <span key={i} style={{ fontSize: '0.7rem', fontWeight: '900', color: '#94a3b8', letterSpacing: '0.08em', textTransform: 'uppercase' }}>{h}</span>
                    ))}
                </div>

                {filtered.length > 0 ? filtered.map(p => {
                    const zone = getZone(p);
                    const zs = getZoneStyle(zone);
                    const pefr = getPefr(p);
                    const displayName = p.name || p.email || 'Unknown';

                    return (
                        <div key={p.id}
                            style={{ padding: '1.5rem 2rem', borderBottom: '1px solid #f1f5f9', display: 'grid', gridTemplateColumns: '56px 1.8fr 1fr 1fr 140px', gap: '1.5rem', alignItems: 'center', transition: 'background 0.15s' }}
                            onMouseEnter={e => e.currentTarget.style.backgroundColor = '#f8fafc'}
                            onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                        >
                            {/* Avatar */}
                            <div style={{ width: '48px', height: '48px', backgroundColor: '#eef2ff', color: '#134e4a', borderRadius: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.1rem', fontWeight: '900', flexShrink: 0 }}>
                                {displayName.charAt(0).toUpperCase()}
                            </div>

                            {/* Identity */}
                            <div>
                                <div style={{ fontSize: '1rem', fontWeight: '900', color: '#0f172a' }}>{displayName}</div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '4px', color: '#94a3b8', fontSize: '0.82rem', fontWeight: '600' }}>
                                    <Mail size={13} /> {p.email}
                                </div>
                            </div>

                            {/* PEFR */}
                            <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.35rem' }}>
                                <span style={{ fontSize: '1.6rem', fontWeight: '900', color: '#0f172a' }}>{pefr ?? '—'}</span>
                                {pefr && <span style={{ fontSize: '0.78rem', fontWeight: '700', color: '#94a3b8' }}>L/min</span>}
                            </div>

                            {/* Zone Badge */}
                            <div>
                                <span style={{ display: 'inline-flex', padding: '0.45rem 1rem', borderRadius: '10px', backgroundColor: zs.bg, color: zs.text, border: `1px solid ${zs.border}`, fontSize: '0.82rem', fontWeight: '900', textTransform: 'uppercase' }}>
                                    {zs.label}
                                </span>
                                {/* Show latest symptom severity underneath if available */}
                                {p.latest_symptom && (
                                    <div style={{ marginTop: '8px', fontSize: '0.72rem', fontWeight: '700', color: '#f59e0b' }}>
                                        {(() => {
                                            const s = p.latest_symptom;
                                            const wheeze = s.wheeze_rating ?? s.wheezeRating ?? 0;
                                            const cough = s.cough_rating ?? s.coughRating ?? 0;
                                            const puffs = s.rescue_inhaler_puffs ?? s.rescueInhalerPuffs ?? 0;
                                            if (wheeze >= 4 || cough >= 4 || puffs >= 5) return '⚠ SEVERE SYMPTOMS';
                                            if (wheeze >= 2 || cough >= 2 || puffs > 0) return '⚠ MILD SYMPTOMS';
                                            return '✓ STABLE SYMPTOMS';
                                        })()}
                                    </div>
                                )}
                            </div>

                            {/* Manage Button */}
                            <button
                                onClick={() => navigate(`/doctor/patient/${p.id}`)}
                                style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0.65rem 1.25rem', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '10px', fontWeight: '800', fontSize: '0.82rem', cursor: 'pointer', transition: 'opacity 0.15s', whiteSpace: 'nowrap' }}
                            >
                                MANAGE <ChevronRight size={15} />
                            </button>
                        </div>
                    );
                }) : (
                    <div style={{ padding: '5rem', textAlign: 'center', color: '#94a3b8' }}>
                        <Users size={48} style={{ opacity: 0.15, marginBottom: '1.25rem' }} />
                        <h3 style={{ fontSize: '1.15rem', fontWeight: '900', margin: '0 0 0.5rem 0' }}>No patients found</h3>
                        <p style={{ fontWeight: '600', margin: 0 }}>Try adjusting the filter or search term.</p>
                    </div>
                )}
            </div>

            <div style={{ height: '3rem' }} />
        </div>
    );
};

export default DoctorDashboard;
