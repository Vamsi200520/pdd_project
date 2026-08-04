import React, { useState, useEffect, useMemo } from 'react';
import { patientService } from '../../services/api';
import { Line } from 'react-chartjs-2';
import { Wind } from 'lucide-react';
import {
    Chart as ChartJS,
    CategoryScale, LinearScale, PointElement, LineElement,
    Title, Tooltip, Filler, Legend,
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Filler, Legend);

const PEFRChart = ({ days = 7 }) => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([
            patientService.getPefrRecords(),
            patientService.getDismissedPefrIds()
        ])
        .then(([records, dismissedIds]) => {
            const dismissedSet = new Set(dismissedIds);
            const filtered = Array.isArray(records) ? records.filter(r => !dismissedSet.has(r.id)) : [];
            setData(filtered);
        })
        .catch(e => console.error('PEFR fetch failed', e))
        .finally(() => setLoading(false));
    }, []);

    const chartData = useMemo(() => {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - days);

        // Backend returns: pefr_value, recorded_at, zone
        const filtered = data.filter(d => {
            const date = new Date(d.recorded_at || d.recordedAt);
            return date >= cutoff;
        });
        const sorted = [...filtered].sort((a, b) =>
            new Date(a.recorded_at || a.recordedAt) - new Date(b.recorded_at || b.recordedAt)
        );

        return {
            labels: sorted.map(d => {
                const date = new Date(d.recorded_at || d.recordedAt);
                return days === 7
                    ? date.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
                    : date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
            }),
            datasets: [{
                fill: true,
                label: 'PEFR (L/min)',
                data: sorted.map(d => d.pefr_value ?? d.pefrValue),
                borderColor: '#134e4a',
                backgroundColor: 'rgba(19, 78, 74, 0.06)',
                tension: 0.4,
                pointBackgroundColor: sorted.map(d => {
                    const z = (d.zone || '').toLowerCase();
                    return z === 'red' ? '#ef4444' : z === 'yellow' ? '#f59e0b' : '#10b981';
                }),
                pointBorderColor: '#ffffff',
                pointBorderWidth: 2,
                pointRadius: 5,
                pointHoverRadius: 7,
            }],
        };
    }, [data, days]);

    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { display: false },
            tooltip: {
                backgroundColor: '#0f172a',
                padding: 14,
                cornerRadius: 12,
                titleFont: { size: 12, weight: 'bold' },
                bodyFont: { size: 15, weight: '900' },
                displayColors: false,
                callbacks: {
                    label: ctx => `${ctx.parsed.y} L/min`
                }
            },
        },
        scales: {
            y: {
                min: 0,
                suggestedMax: 700,
                grid: { color: 'rgba(0,0,0,0.04)' },
                ticks: { font: { size: 11 }, color: '#94a3b8', callback: v => `${v}` }
            },
            x: {
                grid: { display: false },
                ticks: { font: { size: 10 }, color: '#94a3b8' }
            },
        },
        interaction: { mode: 'index', intersect: false },
    };

    if (loading) return (
        <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ width: '30px', height: '30px', border: '3px solid #f1f5f9', borderTopColor: '#134e4a', borderRadius: '50%' }} className="animate-spin" />
        </div>
    );

    if (data.length === 0) return (
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
            <Wind size={48} style={{ opacity: 0.2, marginBottom: '1rem' }} />
            <p style={{ fontWeight: '700', margin: 0 }}>No PEFR records found</p>
            <p style={{ fontWeight: '600', fontSize: '0.85rem', margin: '4px 0 0 0' }}>Record a value to see your clinical chart.</p>
        </div>
    );

    return <Line options={options} data={chartData} />;
};

export default PEFRChart;
