import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { patientService } from '../../services/api';
import {
  ClipboardList, ChevronLeft, AlertCircle, CheckCircle2,
  Loader2, Info, Wind, Activity, Moon, AlertTriangle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

// ── Rating Slider ─────────────────────────────────────────────────────────────
const RatingSlider = ({ title, value, onChange, icon: Icon }) => (
  <div style={{ backgroundColor: '#ffffff', borderRadius: '1.5rem', padding: '1.5rem', border: '1px solid #e2e8f0' }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        {Icon && <div style={{ color: '#134e4a' }}><Icon size={20} /></div>}
        <span style={{ fontWeight: '800', color: '#0f172a', fontSize: '1rem' }}>{title}</span>
      </div>
      <div style={{ backgroundColor: value >= 4 ? '#fef2f2' : value >= 3 ? '#fffbeb' : '#f0fdf4', padding: '0.25rem 0.75rem', borderRadius: '8px', fontWeight: '900', color: value >= 4 ? '#dc2626' : value >= 3 ? '#d97706' : '#134e4a', fontSize: '0.95rem' }}>
        {value}/5
      </div>
    </div>
    <input type="range" min="0" max="5" step="1" value={value}
      onChange={e => onChange(parseInt(e.target.value))}
      style={{ width: '100%', accentColor: '#134e4a', height: '6px', borderRadius: '3px', cursor: 'pointer' }}
    />
    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.5rem', fontSize: '0.68rem', color: '#94a3b8', fontWeight: '700', textTransform: 'uppercase' }}>
      <span>None (0)</span><span>Moderate (3)</span><span>Severe (5)</span>
    </div>
  </div>
);

// ── Main Component ────────────────────────────────────────────────────────────
const SymptomTracker = () => {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);

  const [ratings, setRatings] = useState({
    wheeze_rating: 0,
    cough_rating: 0,
    dyspnea_rating: 0,
    night_symptoms_rating: 0,
    chest_tightness_rating: 0,
    activity_limitation_rating: 0,
  });
  const [rescuePuffs, setRescuePuffs] = useState('');

  const setRating = (key, val) => setRatings(r => ({ ...r, [key]: val }));

  const handleSubmit = async e => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    try {
      // Send exact snake_case keys the backend expects
      await patientService.recordSymptom({
        ...ratings,
        rescue_inhaler_puffs: parseInt(rescuePuffs) || 0,
        onset_at: new Date().toISOString(),
      });
      setSuccess(true);
      setTimeout(() => navigate('/patient/dashboard'), 2000);
    } catch (err) {
      setError('Sync failed. Please check your connection and try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const getPuffsStatus = val => {
    const n = parseInt(val);
    if (isNaN(n) || n === 0) return { color: '#94a3b8', text: 'No rescue usage today' };
    if (n >= 8) return { color: '#ef4444', text: '⚠ Critical — Contact your doctor immediately' };
    if (n >= 4) return { color: '#f59e0b', text: 'Frequent usage — Monitor closely' };
    return { color: '#10b981', text: 'Standard therapeutic range' };
  };

  const puffStatus = getPuffsStatus(rescuePuffs);

  return (
    <div style={{ maxWidth: '900px', margin: '0 auto' }}>
      {/* HEADER */}
      <div style={{ marginBottom: '2.5rem' }}>
        <button onClick={() => navigate('/patient/dashboard')}
          style={{ background: 'none', border: 'none', color: '#64748b', display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', padding: 0, fontWeight: '800', fontSize: '0.8rem', marginBottom: '1rem' }}>
          <ChevronLeft size={16} /> RETURN TO DASHBOARD
        </button>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <h1 style={{ fontSize: '2.5rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Symptom Tracker</h1>
            <p style={{ color: '#64748b', fontSize: '1rem', fontWeight: '500', marginTop: '4px' }}>Rate your clinical observations for professional review.</p>
          </div>
          <div style={{ backgroundColor: '#eef2ff', padding: '0.85rem 1.25rem', borderRadius: '1.25rem', border: '1px solid #e0e7ff', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <Activity size={20} color="#134e4a" />
            <div>
              <div style={{ fontSize: '0.65rem', fontWeight: '900', color: '#4338ca', letterSpacing: '0.1em' }}>PRECISION SCALE</div>
              <div style={{ fontSize: '0.95rem', fontWeight: '800', color: '#134e4a' }}>0 – 5 Clinical Rating</div>
            </div>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>

        {/* RATING SLIDERS GRID */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
          <RatingSlider title="Wheezing" value={ratings.wheeze_rating} onChange={v => setRating('wheeze_rating', v)} icon={Wind} />
          <RatingSlider title="Cough Severity" value={ratings.cough_rating} onChange={v => setRating('cough_rating', v)} icon={Activity} />
          <RatingSlider title="Shortness of Breath" value={ratings.dyspnea_rating} onChange={v => setRating('dyspnea_rating', v)} icon={Wind} />
          <RatingSlider title="Nighttime Symptoms" value={ratings.night_symptoms_rating} onChange={v => setRating('night_symptoms_rating', v)} icon={Moon} />
          <RatingSlider title="Chest Tightness" value={ratings.chest_tightness_rating} onChange={v => setRating('chest_tightness_rating', v)} icon={Activity} />
          <RatingSlider title="Activity Limitation" value={ratings.activity_limitation_rating} onChange={v => setRating('activity_limitation_rating', v)} icon={Activity} />
        </div>

        {/* RESCUE INHALER */}
        <div style={{ backgroundColor: '#0f172a', borderRadius: '2rem', padding: '2.5rem', color: '#ffffff', display: 'flex', flexWrap: 'wrap', gap: '2.5rem', alignItems: 'center' }}>
          <div style={{ flex: 1, minWidth: '280px' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: '900', margin: '0 0 0.5rem 0' }}>Rescue Inhaler Usage</h3>
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', margin: 0 }}>Valid range: 0 – 10 puffs/day (NHS clinical standard)</p>
            <div style={{ marginTop: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', color: puffStatus.color }}>
              {parseInt(rescuePuffs) >= 8 ? <AlertTriangle size={20} /> : <Info size={20} />}
              <span style={{ fontWeight: '700', fontSize: '0.92rem' }}>{puffStatus.text}</span>
            </div>
          </div>
          <div style={{ textAlign: 'center' }}>
            <input type="number" value={rescuePuffs}
              onChange={e => {
                const v = e.target.value;
                if (v === '' || (parseInt(v) >= 0 && parseInt(v) <= 10)) setRescuePuffs(v);
              }}
              placeholder="0" min="0" max="10"
              style={{ width: '160px', height: '80px', textAlign: 'center', fontSize: '2.5rem', fontWeight: '900', borderRadius: '1.5rem', border: '2px solid rgba(255,255,255,0.1)', backgroundColor: 'rgba(255,255,255,0.08)', color: '#ffffff', outline: 'none' }}
            />
            <div style={{ marginTop: '0.75rem', fontSize: '0.75rem', fontWeight: '900', color: '#4db6ac', letterSpacing: '0.2em' }}>PUFFS TODAY</div>
          </div>
        </div>

        {/* FEEDBACK */}
        <AnimatePresence>
          {error && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
              style={{ padding: '1.25rem', backgroundColor: '#fef2f2', border: '1px solid #fee2e2', borderRadius: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem', color: '#dc2626' }}>
              <AlertCircle size={20} /> <span style={{ fontWeight: '700' }}>{error}</span>
            </motion.div>
          )}
          {success && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
              style={{ padding: '1.25rem', backgroundColor: '#f0fdf4', border: '1px solid #dcfce7', borderRadius: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem', color: '#16a34a' }}>
              <CheckCircle2 size={20} /> <span style={{ fontWeight: '700' }}>Clinical observations saved and synchronized!</span>
            </motion.div>
          )}
        </AnimatePresence>

        <button type="submit" disabled={isLoading || success}
          style={{ width: '100%', height: '68px', backgroundColor: success ? '#10b981' : '#134e4a', color: '#ffffff', border: 'none', borderRadius: '1.5rem', fontWeight: '900', fontSize: '1.1rem', cursor: isLoading || success ? 'default' : 'pointer', boxShadow: '0 8px 15px -3px rgba(19,78,74,0.35)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', transition: 'all 0.3s' }}>
          {isLoading ? <><Loader2 size={24} className="animate-spin" /> SYNCING...</> : success ? <><CheckCircle2 size={24} /> OBSERVATIONS SAVED!</> : 'SUBMIT CLINICAL OBSERVATIONS'}
        </button>
      </form>
      <div style={{ height: '5rem' }} />
    </div>
  );
};

export default SymptomTracker;
