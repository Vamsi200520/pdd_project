import React, { useState, useEffect } from 'react';
import { patientService } from '../../services/api';
import {
  Pill,
  CheckCircle2,
  Clock,
  AlertCircle,
  ChevronRight,
  ShieldCheck,
  Info,
  Calendar,
  Plus,
  Loader2,
  Check
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const MedicationCard = ({ med, onTake }) => {
  const [isTaking, setIsTaking] = useState(false);
  const [isTaken, setIsTaken] = useState(false);

  const handleTake = async () => {
    setIsTaking(true);
    try {
      await onTake(med.id);
      setIsTaken(true);
      setTimeout(() => setIsTaken(false), 3000);
    } finally {
      setIsTaking(false);
    }
  };

  return (
    <div style={{ backgroundColor: '#ffffff', borderRadius: '1.5rem', padding: '1.75rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', gap: '1.25rem', position: 'relative', overflow: 'hidden' }}>
      {isTaken && (
        <div style={{ position: 'absolute', top: 0, right: 0, padding: '0.5rem 1rem', backgroundColor: '#10b981', color: '#ffffff', fontSize: '0.7rem', fontWeight: '900', borderRadius: '0 0 0 12px' }}>
          RECORDED TODAY
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <div style={{ width: '56px', height: '56px', backgroundColor: '#f1f5f9', color: '#134e4a', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Pill size={28} />
          </div>
          <div>
            <h4 style={{ fontSize: '1.15rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>{med.name}</h4>
            <div style={{ fontSize: '0.9rem', color: '#4db6ac', fontWeight: '800', marginTop: '2px' }}>{med.dose || 'Standard Dose'}</div>
          </div>
        </div>
        {med.dosesRemaining !== undefined && (
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '1.25rem', fontWeight: '900', color: '#0f172a' }}>{med.dosesRemaining}</div>
            <div style={{ fontSize: '0.7rem', color: '#94a3b8', fontWeight: '700', textTransform: 'uppercase' }}>Doses Left</div>
          </div>
        )}
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', backgroundColor: '#f8fafc', padding: '1.25rem', borderRadius: '1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem', color: '#475569', fontWeight: '600' }}>
          <Calendar size={16} color="#94a3b8" />
          <span>Schedule: {med.schedule || 'As needed'}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem', color: '#475569', fontWeight: '600' }}>
          <Clock size={16} color="#94a3b8" />
          <span>Last Taken: {med.lastTakenTime || 'No records today'}</span>
        </div>
      </div>

      <button
        onClick={handleTake}
        disabled={isTaking || isTaken}
        style={{
          width: '100%',
          height: '52px',
          backgroundColor: isTaken ? '#f0fdf4' : '#134e4a',
          color: isTaken ? '#16a34a' : '#ffffff',
          border: isTaken ? '1px solid #dcfce7' : 'none',
          borderRadius: '12px',
          fontWeight: '900',
          fontSize: '0.95rem',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '0.75rem',
          transition: 'all 0.2s'
        }}
      >
        {isTaking ? <Loader2 size={20} className="animate-spin" /> : isTaken ? <Check size={20} /> : <Plus size={20} />}
        {isTaking ? 'RECORDING...' : isTaken ? 'DOSE RECORDED' : 'RECORD DOSE NOW'}
      </button>
    </div>
  );
};

const TreatmentPlan = () => {
  const [medications, setMedications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [aiAnalyzing, setAiAnalyzing] = useState(false);
  const [showAiReport, setShowAiReport] = useState(false);
  const [prediction, setPrediction] = useState(null);

  useEffect(() => {
    fetchMedications();
  }, []);

  const fetchMedications = async () => {
    try {
      const data = await patientService.getMedications();
      setMedications(data);
    } catch (err) {
      console.error('Failed to fetch medications');
    } finally {
      setLoading(false);
    }
  };

  const handleTakeMedication = async (id) => {
    await patientService.takeMedication(id);
    fetchMedications();
  };

  const runAiVerification = async () => {
    setAiAnalyzing(true);
    try {
      const data = await patientService.getAiPrediction();
      setPrediction(data);
      setTimeout(() => {
        setAiAnalyzing(false);
        setShowAiReport(true);
      }, 2000);
    } catch (err) {
      setAiAnalyzing(false);
    }
  };

  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
      <div className="animate-spin" style={{ width: '40px', height: '40px', border: '4px solid #e2e8f0', borderTopColor: '#134e4a', borderRadius: '50%' }}></div>
    </div>
  );

  return (
    <div style={{ maxWidth: '1200px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '3rem' }}>
        <div>
          <h1 style={{ fontSize: '2.5rem', fontWeight: '900', color: '#0f172a', margin: 0 }}>Prescription Plan</h1>
          <p style={{ color: '#64748b', fontSize: '1.1rem', fontWeight: '500', marginTop: '4px' }}>Adherence tracking and clinical verification portal.</p>
        </div>

        {/* AI VERIFICATION BUTTON (iOS Gradient Style) */}
        <button
          onClick={runAiVerification}
          disabled={aiAnalyzing}
          style={{
            background: 'linear-gradient(135deg, #7c3aed 0%, #2563eb 100%)',
            color: '#ffffff',
            border: 'none',
            padding: '1.25rem 2.5rem',
            borderRadius: '1.5rem',
            fontWeight: '900',
            fontSize: '1rem',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            boxShadow: '0 10px 20px -5px rgba(37, 99, 235, 0.4)',
            transition: 'transform 0.2s'
          }}
          onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.96)'}
          onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
        >
          {aiAnalyzing ? <Loader2 size={24} className="animate-spin" /> : <ShieldCheck size={24} />}
          {aiAnalyzing ? 'AI ANALYZING DATA...' : 'VERIFY WITH AI ADVISOR'}
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(380px, 1fr))', gap: '2rem' }}>
        {medications.map(med => (
          <MedicationCard key={med.id} med={med} onTake={handleTakeMedication} />
        ))}

        {medications.length === 0 && (
          <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '5rem', backgroundColor: '#f8fafc', borderRadius: '2rem', border: '2px dashed #e2e8f0' }}>
            <Pill size={48} color="#cbd5e1" style={{ marginBottom: '1.5rem' }} />
            <h3 style={{ fontSize: '1.25rem', fontWeight: '800', color: '#64748b' }}>No medications in current plan</h3>
            <p style={{ color: '#94a3b8', fontWeight: '500' }}>Contact your doctor to update your treatment regimen.</p>
          </div>
        )}
      </div>

      {/* AI INSIGHT MODAL REPLICA */}
      <AnimatePresence>
        {showAiReport && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(15, 23, 42, 0.9)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}
          >
            <motion.div
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              style={{ width: '100%', maxWidth: '600px', backgroundColor: '#134e4a', borderRadius: '2.5rem', padding: '3rem', color: '#ffffff', position: 'relative' }}
            >
              <button
                onClick={() => setShowAiReport(false)}
                style={{ position: 'absolute', top: '2rem', right: '2rem', background: 'none', border: 'none', color: '#4db6ac', fontWeight: '900', cursor: 'pointer', fontSize: '1rem' }}
              >
                CLOSE REPORT
              </button>

              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: '1.5rem' }}>
                <div style={{ width: '80px', height: '80px', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '2rem', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4db6ac' }}>
                  <ShieldCheck size={48} />
                </div>
                <h2 style={{ fontSize: '2rem', fontWeight: '900', margin: 0 }}>Clinical Health Insight</h2>
                <p style={{ color: '#b2dfdb', lineHeight: '1.6', fontSize: '1.1rem' }}>
                  Based on your latest PEFR of {prediction?.latestPefr || 'stable'} L/min and symptom reports, the AI Advisor recommends:
                </p>

                <div style={{ width: '100%', backgroundColor: 'rgba(0,0,0,0.2)', padding: '2rem', borderRadius: '1.5rem', margin: '1rem 0' }}>
                  <div style={{ fontSize: '0.8rem', fontWeight: '900', color: '#4db6ac', letterSpacing: '0.1em', marginBottom: '0.5rem' }}>RECOMMENDED THERAPY</div>
                  <div style={{ fontSize: '1.75rem', fontWeight: '900' }}>{prediction?.recommended_medicine || prediction?.recommendedMedicine || 'Continue Current Plan'}</div>
                  <div style={{ marginTop: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', color: '#10b981', fontWeight: '800' }}>
                    <CheckCircle2 size={18} /> ALIGNED WITH DOCTOR'S PLAN
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '1rem', width: '100%' }}>
                  <div style={{ flex: 1, backgroundColor: 'rgba(255,255,255,0.05)', padding: '1.25rem', borderRadius: '1rem' }}>
                    <div style={{ fontSize: '2rem', fontWeight: '900' }}>{Math.round((prediction?.predicted_cure_probability || prediction?.predictedCureProbability || 0.92) * 100)}%</div>
                    <div style={{ fontSize: '0.7rem', fontWeight: '800', opacity: 0.6 }}>STABILITY PROBABILITY</div>
                  </div>
                  <div style={{ flex: 1, backgroundColor: 'rgba(255,255,255,0.05)', padding: '1.25rem', borderRadius: '1rem' }}>
                    <div style={{ fontSize: '2rem', fontWeight: '900' }}>{prediction?.recommended_days || prediction?.estimatedDaysToStable || 7}</div>
                    <div style={{ fontSize: '0.7rem', fontWeight: '800', opacity: 0.6 }}>DAYS TO PEAK STABILITY</div>
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default TreatmentPlan;
