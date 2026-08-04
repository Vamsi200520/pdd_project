import { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { profileService, patientService } from '../../services/api';
import {
  User, Mail, Phone, MapPin, Ruler, Calendar, Heart, Shield, Stethoscope, Edit2, X, Loader2
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const ProfilePage = () => {
  const { user } = useAuth();
  const [localUser, setLocalUser] = useState(user);
  const [isEditing, setIsEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [modalErrors, setModalErrors] = useState({});

  // Form states
  const [formData, setFormData] = useState({
    name: user?.name || user?.fullName || '',
    contact_number: user?.contact_number || '',
    address: user?.address || '',
    age: user?.age || '',
    height: user?.height || '',
    gender: user?.gender || '',
    baseline: user?.baseline?.baseline_value || ''
  });

  const isDoctor = localUser?.role?.toLowerCase() === 'doctor';
  const displayName = localUser?.name || localUser?.fullName || 'User';

  const handleLogout = () => {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_role');
    window.location.href = '/login';
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    let updatedValue = value;

    // Keep inputs strictly restricted to matching iOS guidelines
    if (name === 'contact_number') {
      updatedValue = value.replace(/\D/g, '').slice(0, 10);
    } else if (name === 'name') {
      updatedValue = value.replace(/[^a-zA-Z\s]/g, '').slice(0, 50);
    } else if (name === 'age') {
      updatedValue = value.replace(/\D/g, '').slice(0, 3);
    } else if (name === 'height') {
      updatedValue = value.replace(/\D/g, '').slice(0, 3);
    } else if (name === 'baseline') {
      updatedValue = value.replace(/\D/g, '').slice(0, 3);
    } else if (name === 'address') {
      updatedValue = value.slice(0, 150);
    }

    setFormData(prev => ({ ...prev, [name]: updatedValue }));
    
    // Clear error for this field
    if (modalErrors[name]) {
      setModalErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateModalForm = () => {
    const errors = {};
    const { name, contact_number, address, age, height, baseline } = formData;

    // Full Name
    if (!name.trim()) {
      errors.name = 'Full Name is required';
    } else if (!/^[a-zA-Z\s]+$/.test(name)) {
      errors.name = 'Name should only contain characters';
    }

    // Contact Number
    if (!contact_number) {
      errors.contact_number = 'Required';
    } else if (contact_number.length !== 10) {
      errors.contact_number = 'Must be exactly 10 digits';
    } else if (!['6', '7', '8', '9'].includes(contact_number[0])) {
      errors.contact_number = 'Enter valid Indian number (6-9 start)';
    }

    // Address
    if (!address.trim()) {
      errors.address = 'Address is required';
    }

    // Patient specific validation
    if (!isDoctor) {
      const ageInt = parseInt(age, 10);
      if (isNaN(ageInt) || ageInt <= 0 || ageInt >= 120) {
        errors.age = 'Valid age (1-119)';
      }

      const heightInt = parseInt(height, 10);
      if (isNaN(heightInt) || heightInt <= 30 || heightInt >= 300) {
        errors.height = 'Valid height (30-300)';
      }

      if (baseline) {
        const baselineInt = parseInt(baseline, 10);
        if (isNaN(baselineInt) || baselineInt <= 0 || baselineInt > 999) {
          errors.baseline = 'Valid baseline value required';
        }
      }
    }

    setModalErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSave = async () => {
    if (!validateModalForm()) {
      return;
    }

    setSaving(true);
    try {
      // Update profile
      const updated = await profileService.updateProfile({
        name: formData.name,
        contact_number: formData.contact_number,
        address: formData.address,
        age: formData.age ? parseInt(formData.age, 10) : null,
        height: formData.height ? parseInt(formData.height, 10) : null,
        gender: formData.gender
      }, localUser);

      // Update baseline if it's a patient and changed
      if (!isDoctor && formData.baseline && formData.baseline !== (localUser?.baseline?.baseline_value || '')) {
        await patientService.setBaseline(parseInt(formData.baseline, 10));
        // fetch again
        const finalProfile = await profileService.getProfile();
        setLocalUser(finalProfile);
      } else {
        setLocalUser(updated);
      }

      setIsEditing(false);
    } catch (err) {
      console.error('Failed to update profile:', err);
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = (hasError) => ({
    width: '100%',
    padding: '1rem',
    borderRadius: '12px',
    border: hasError ? '2px solid #dc2626' : '2px solid #e2e8f0',
    color: '#0f172a',
    fontWeight: '700',
    fontSize: '1rem',
    outline: 'none',
    boxSizing: 'border-box'
  });

  const errorLabelStyle = {
    color: '#dc2626',
    fontSize: '0.75rem',
    fontWeight: '700',
    marginTop: '4px'
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem', maxWidth: '900px' }}>

      {/* PROFILE HERO */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
        style={{ backgroundColor: '#134e4a', borderRadius: '2rem', padding: '3rem', color: '#ffffff', display: 'flex', alignItems: 'center', gap: '2.5rem', position: 'relative' }}>
        <div style={{ width: '110px', height: '110px', backgroundColor: 'rgba(255,255,255,0.15)', borderRadius: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '3rem', fontWeight: '900', border: '3px solid rgba(255,255,255,0.25)', flexShrink: 0 }}>
          {displayName.charAt(0).toUpperCase()}
        </div>

        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
            {isDoctor ? <Stethoscope size={22} color="#4db6ac" /> : <Shield size={22} color="#4db6ac" />}
            <span style={{ fontSize: '0.8rem', fontWeight: '900', letterSpacing: '0.15em', color: '#4db6ac', textTransform: 'uppercase' }}>
              {isDoctor ? 'Certified Clinician' : 'Patient Account'}
            </span>
          </div>
          <h1 style={{ fontSize: '2.25rem', fontWeight: '900', margin: '0 0 0.5rem 0' }}>{displayName}</h1>
          <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: '1rem', fontWeight: '600', margin: 0 }}>{localUser?.email}</p>
        </div>

        <button onClick={() => {
          setFormData({
            name: localUser?.name || localUser?.fullName || '',
            contact_number: localUser?.contact_number || '',
            address: localUser?.address || '',
            age: localUser?.age || '',
            height: localUser?.height || '',
            gender: localUser?.gender || '',
            baseline: localUser?.baseline?.baseline_value || ''
          });
          setModalErrors({});
          setIsEditing(true);
        }}
          style={{ position: 'absolute', top: '2rem', right: '2rem', backgroundColor: 'rgba(255,255,255,0.1)', border: 'none', color: '#fff', padding: '0.75rem 1.25rem', borderRadius: '12px', fontWeight: '800', fontSize: '0.85rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem', transition: 'all 0.2s' }}>
          <Edit2 size={16} /> EDIT PROFILE
        </button>
      </motion.div>

      {/* DETAILS GRID */}
      <div style={{ display: 'grid', gridTemplateColumns: isDoctor ? '1fr' : '1fr 1fr', gap: '1.5rem' }}>

        {/* PERSONAL DETAILS */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}
          style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2.5rem', border: '1px solid #e2e8f0' }}>
          <h2 style={{ fontSize: '1.15rem', fontWeight: '900', color: '#0f172a', margin: '0 0 2rem 0' }}>Personal Details</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            {[
              { Icon: User, label: 'Full Name', value: displayName },
              { Icon: Mail, label: 'Email Address', value: localUser?.email || '—' },
              { Icon: Phone, label: 'Contact', value: localUser?.contact_number || '—' },
              { Icon: MapPin, label: 'Address', value: localUser?.address || '—' },
            ].map(({ Icon, label, value }) => (
              <div key={label} style={{ display: 'flex', alignItems: 'flex-start', gap: '1.25rem' }}>
                <div style={{ width: '44px', height: '44px', backgroundColor: '#f1f5f9', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon size={18} color="#64748b" />
                </div>
                <div style={{ flex: 1, wordBreak: 'break-word' }}>
                  <p style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', margin: '0 0 3px 0', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{label}</p>
                  <p style={{ fontSize: '1rem', fontWeight: '700', color: '#0f172a', margin: 0 }}>{value}</p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* HEALTH PROFILE — patients only */}
        {!isDoctor && (
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}
            style={{ backgroundColor: '#ffffff', borderRadius: '2rem', padding: '2.5rem', border: '1px solid #e2e8f0' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: '900', color: '#0f172a', margin: '0 0 2rem 0' }}>Health Profile</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              {[
                { Icon: Calendar, label: 'Age', value: localUser?.age ? `${localUser.age} years` : '—' },
                { Icon: User, label: 'Gender', value: localUser?.gender || '—' },
                { Icon: Ruler, label: 'Height', value: localUser?.height ? `${localUser.height} cm` : '—' },
                { Icon: Heart, label: 'Baseline PEFR', value: localUser?.baseline?.baseline_value ? `${localUser.baseline.baseline_value} L/min` : '—' },
              ].map(({ Icon, label, value }) => (
                <div key={label} style={{ display: 'flex', alignItems: 'flex-start', gap: '1.25rem' }}>
                  <div style={{ width: '44px', height: '44px', backgroundColor: '#eef2ff', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Icon size={18} color="#134e4a" />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', fontWeight: '800', color: '#94a3b8', margin: '0 0 3px 0', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{label}</p>
                    <p style={{ fontSize: '1rem', fontWeight: '700', color: '#0f172a', margin: 0 }}>{value}</p>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </div>

      {/* LOGOUT BUTTON */}
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.3 }}>
        <button
          onClick={handleLogout}
          style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '1rem 2rem', backgroundColor: '#fef2f2', color: '#dc2626', border: '1px solid #fee2e2', borderRadius: '1.25rem', fontWeight: '900', fontSize: '1rem', cursor: 'pointer', transition: 'all 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.backgroundColor = '#fee2e2'}
          onMouseLeave={e => e.currentTarget.style.backgroundColor = '#fef2f2'}
        >
          Secure Logout
        </button>
      </motion.div>

      {/* EDIT PROFILE MODAL */}
      <AnimatePresence>
        {isEditing && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(15,23,42,0.85)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}
            onClick={e => { if (e.target === e.currentTarget) setIsEditing(false); }}>

            <motion.div initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9 }}
              style={{ backgroundColor: '#ffffff', borderRadius: '2.5rem', padding: '3rem', width: '100%', maxWidth: '600px', position: 'relative', maxHeight: '90vh', overflowY: 'auto' }}>
              <button onClick={() => setIsEditing(false)}
                style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: '#f1f5f9', border: 'none', color: '#64748b', borderRadius: '50%', width: '36px', height: '36px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <X size={18} />
              </button>

              <h2 style={{ fontSize: '1.75rem', fontWeight: '900', color: '#0f172a', margin: '0 0 2rem 0' }}>Edit Profile</h2>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                {/* NAME */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>FULL NAME</label>
                  <input name="name" value={formData.name} onChange={handleInputChange}
                    style={inputStyle(!!modalErrors.name)} />
                  {modalErrors.name && <div style={errorLabelStyle}>{modalErrors.name}</div>}
                </div>

                {/* CONTACT */}
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>CONTACT NUMBER</label>
                  <input name="contact_number" value={formData.contact_number} onChange={handleInputChange}
                    style={inputStyle(!!modalErrors.contact_number)} />
                  {modalErrors.contact_number && <div style={errorLabelStyle}>{modalErrors.contact_number}</div>}
                </div>

                {/* ADDRESS */}
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>ADDRESS</label>
                  <input name="address" value={formData.address} onChange={handleInputChange}
                    style={inputStyle(!!modalErrors.address)} />
                  {modalErrors.address && <div style={errorLabelStyle}>{modalErrors.address}</div>}
                </div>

                {/* PATIENT ONLY FIELDS */}
                {!isDoctor && (
                  <>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>AGE</label>
                      <input name="age" type="text" inputMode="numeric" value={formData.age} onChange={handleInputChange}
                        style={inputStyle(!!modalErrors.age)} />
                      {modalErrors.age && <div style={errorLabelStyle}>{modalErrors.age}</div>}
                    </div>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>GENDER</label>
                      <select name="gender" value={formData.gender} onChange={e => setFormData({ ...formData, gender: e.target.value })}
                        style={{ ...inputStyle(false), appearance: 'none', backgroundColor: '#fff' }}>
                        <option value="">Select Gender</option>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                        <option value="Other">Other</option>
                      </select>
                    </div>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>HEIGHT (cm)</label>
                      <input name="height" type="text" inputMode="numeric" value={formData.height} onChange={handleInputChange}
                        style={inputStyle(!!modalErrors.height)} />
                      {modalErrors.height && <div style={errorLabelStyle}>{modalErrors.height}</div>}
                    </div>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: '900', color: '#64748b', display: 'block', marginBottom: '0.5rem', letterSpacing: '0.1em' }}>BASELINE PEFR (Optional)</label>
                      <input name="baseline" type="text" inputMode="numeric" value={formData.baseline} onChange={handleInputChange}
                        style={inputStyle(!!modalErrors.baseline)} />
                      {modalErrors.baseline && <div style={errorLabelStyle}>{modalErrors.baseline}</div>}
                    </div>
                  </>
                )}
              </div>

              <button onClick={handleSave} disabled={saving}
                style={{ width: '100%', height: '56px', backgroundColor: '#134e4a', color: '#ffffff', border: 'none', borderRadius: '14px', fontWeight: '900', fontSize: '1rem', cursor: 'pointer', transition: 'all 0.2s', marginTop: '2.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {saving ? <Loader2 className="animate-spin" size={24} style={{ margin: 'auto' }} /> : 'SAVE CHANGES'}
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <div style={{ height: '3rem' }} />
    </div>
  );
};

export default ProfilePage;
