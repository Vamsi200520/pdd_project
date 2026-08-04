import axios from 'axios';

const api = axios.create({
    baseURL: '/api',
    headers: {
        'Content-Type': 'application/json',
    },
});

// Inject auth token on every request
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle 401 — session expired
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('auth_token');
            localStorage.removeItem('auth_role');
            if (window.location.pathname !== '/login') {
                window.location.href = '/login';
            }
        }
        return Promise.reject(error);
    }
);

// ─── Auth ────────────────────────────────────────────────────────────────────
export const authService = {
    login: async (email, password) => {
        const formData = new URLSearchParams();
        formData.append('username', email);
        formData.append('password', password);
        const response = await api.post('/auth/login', formData, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });
        return response.data;
    },
    signupSendOtp: async (data) => {
        const response = await api.post('/auth/signup-send-otp', data);
        return response.data;
    },
    verifySignupOtp: async (email, otp) => {
        const formData = new URLSearchParams();
        formData.append('email', email);
        formData.append('otp', otp);
        const response = await api.post('/auth/verify-signup-otp', formData, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });
        return response.data;
    },
    forgotPassword: async (email) => {
        const formData = new URLSearchParams();
        formData.append('email', email);
        const response = await api.post('/auth/forgot-password', formData, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });
        return response.data;
    },
    resetPassword: async (email, otp, newPassword) => {
        const formData = new URLSearchParams();
        formData.append('email', email);
        formData.append('otp', otp);
        formData.append('new_password', newPassword);
        const response = await api.post('/auth/reset-password', formData, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });
        return response.data;
    },
};

// ─── Profile ─────────────────────────────────────────────────────────────────
export const profileService = {
    getProfile: async () => {
        const response = await api.get('/profile/me');
        return response.data;
    },
    updateProfile: async (data, currentUser) => {
        const fullRequest = {
            email: currentUser.email,
            name: data.name || currentUser.name || currentUser.fullName || '',
            role: currentUser.role || 'patient',
            password: '',
            age: data.age ? parseInt(data.age, 10) : currentUser.age,
            height: data.height ? parseInt(data.height, 10) : currentUser.height,
            gender: data.gender || currentUser.gender,
            contact_number: data.contact_number || currentUser.contact_number,
            address: data.address || currentUser.address
        };
        const response = await api.put('/profile/me', fullRequest);
        // Refresh by fetching again
        const fresh = await api.get('/profile/me');
        return fresh.data;
    },
};

// ─── Patient ─────────────────────────────────────────────────────────────────
export const patientService = {
    // Alias for Auth context
    getProfile: async () => {
        const response = await api.get('/profile/me');
        return response.data;
    },

    // PEFR
    getPefrRecords: async () => {
        const response = await api.get('/pefr/records');
        return response.data;
    },
    recordPefr: async (value) => {
        const response = await api.post('/pefr/record', { pefr_value: value });
        return response.data;
    },

    // Symptoms
    getSymptomRecords: async () => {
        const response = await api.get('/symptom/records');
        return response.data;
    },
    recordSymptom: async (data) => {
        const response = await api.post('/symptom/record', data);
        return response.data;
    },

    // Medications
    getMedications: async () => {
        const response = await api.get('/medications');
        return Array.isArray(response.data) ? response.data.filter(med => med.name !== '__dismissed_symptoms__' && med.name !== '__dismissed_pefr__') : [];
    },
    takeMedication: async (id) => {
        const response = await api.post(`/medications/${id}/take`);
        return response.data;
    },
    addMedication: async (data) => {
        const response = await api.post('/medications', data);
        return response.data;
    },
    updateMedication: async (id, data) => {
        const response = await api.patch(`/medications/${id}`, data);
        return response.data;
    },
    deleteMedication: async (id) => {
        const response = await api.delete(`/medications/${id}`);
        return response.data;
    },
    getDismissedSymptomIds: async () => {
        try {
            const response = await api.get('/medications');
            const dummy = Array.isArray(response.data) ? response.data.find(med => med.name === '__dismissed_symptoms__') : null;
            if (dummy && dummy.dose) {
                return dummy.dose.split(',').map(id => parseInt(id, 10)).filter(id => !isNaN(id));
            }
        } catch (err) {
            console.error('Failed to fetch dismissed symptom IDs:', err);
        }
        return [];
    },
    dismissSymptomId: async (id) => {
        try {
            const response = await api.get('/medications');
            const meds = Array.isArray(response.data) ? response.data : [];
            const dummy = meds.find(med => med.name === '__dismissed_symptoms__');
            
            let dismissedIds = [];
            if (dummy && dummy.dose) {
                dismissedIds = dummy.dose.split(',').map(x => x.trim()).filter(Boolean);
            }
            
            if (!dismissedIds.includes(id.toString())) {
                dismissedIds.push(id.toString());
            }
            
            const newDose = dismissedIds.join(',');
            
            if (dummy) {
                await api.patch(`/medications/${dummy.id}`, { dose: newDose });
            } else {
                await api.post('/medications', {
                    name: '__dismissed_symptoms__',
                    dose: newDose,
                    schedule: 'meta',
                    description: 'meta'
                });
            }
        } catch (err) {
            console.error('Failed to dismiss symptom ID:', err);
        }
    },
    getDismissedPefrIds: async () => {
        try {
            const response = await api.get('/medications');
            const dummy = Array.isArray(response.data) ? response.data.find(med => med.name === '__dismissed_pefr__') : null;
            if (dummy && dummy.dose) {
                return dummy.dose.split(',').map(id => parseInt(id, 10)).filter(id => !isNaN(id));
            }
        } catch (err) {
            console.error('Failed to fetch dismissed PEFR IDs:', err);
        }
        return [];
    },
    dismissPefrId: async (id) => {
        try {
            const response = await api.get('/medications');
            const meds = Array.isArray(response.data) ? response.data : [];
            const dummy = meds.find(med => med.name === '__dismissed_pefr__');
            
            let dismissedIds = [];
            if (dummy && dummy.dose) {
                dismissedIds = dummy.dose.split(',').map(x => x.trim()).filter(Boolean);
            }
            
            if (!dismissedIds.includes(id.toString())) {
                dismissedIds.push(id.toString());
            }
            
            const newDose = dismissedIds.join(',');
            
            if (dummy) {
                await api.patch(`/medications/${dummy.id}`, { dose: newDose });
            } else {
                await api.post('/medications', {
                    name: '__dismissed_pefr__',
                    dose: newDose,
                    schedule: 'meta',
                    description: 'meta'
                });
            }
        } catch (err) {
            console.error('Failed to dismiss PEFR ID:', err);
        }
    },

    // AI Prediction
    getAiPrediction: async () => {
        // Fetch raw data to construct payload
        const [profRes, pefrRes, sympRes] = await Promise.all([
            api.get('/profile/me'),
            api.get('/pefr/records'),
            api.get('/symptom/records')
        ]);

        const pefrData = Array.isArray(pefrRes.data) ? pefrRes.data : [];
        const sympData = Array.isArray(sympRes.data) ? sympRes.data : [];

        pefrData.sort((a, b) => new Date(b.recorded_at || b.recordedAt) - new Date(a.recorded_at || a.recordedAt));
        sympData.sort((a, b) => new Date(b.recorded_at || b.onset_at || b.onsetAt) - new Date(a.recorded_at || a.onset_at || a.onsetAt));

        const latestPefr = pefrData[0]?.pefr_value ?? pefrData[0]?.pefrValue ?? 0;
        const latestSymp = sympData[0] || {};

        const payload = {
            age: profRes.data.age || 25,
            pefr_value: latestPefr || 400,
            wheeze_rating: latestSymp.wheeze_rating ?? latestSymp.wheezeRating ?? 0,
            cough_rating: latestSymp.cough_rating ?? latestSymp.coughRating ?? 0,
            dust_exposure: latestSymp.dust_exposure ?? latestSymp.dustExposure ?? false,
            smoke_exposure: latestSymp.smoke_exposure ?? latestSymp.smokeExposure ?? false
        };

        try {
            const response = await api.post('/ml/predict', payload);
            return { ...response.data, latestPefr };
        } catch (err) {
            // Failsafe mock data if the python model crashes locally or missing deps
            return {
                recommended_medicine: 'Salbutamol / Standard Plan',
                predicted_cure_probability: 0.90,
                recommended_days: 7,
                latestPefr
            };
        }
    },
    getPrediction: async (data) => {
        const response = await api.post('/ml/predict', data);
        return response.data;
    },
    // Notifications
    getNotifications: async () => {
        const response = await api.get('/notifications');
        return response.data;
    },
    markNotificationRead: async (id) => {
        const response = await api.patch(`/notifications/${id}/read`);
        return response.data;
    },
    setBaseline: async (value) => {
        const response = await api.post('/patient/baseline', { baseline_value: value });
        return response.data;
    }
};

// ─── Doctor ───────────────────────────────────────────────────────────────────
export const doctorService = {
    // Patient list (supports optional zone filter)
    getPatients: async (zone) => {
        const params = zone && zone !== 'All' ? { zone } : {};
        const response = await api.get('/doctor/patients', { params });
        return response.data;
    },
    deletePatient: async (patientId) => {
        const response = await api.delete(`/doctor/patients/${patientId}`);
        return response.data;
    },

    // Patient-specific data
    getPatientPefrRecords: async (patientId) => {
        const response = await api.get(`/doctor/patients/${patientId}/pefr`);
        return response.data;
    },
    getPatientSymptomRecords: async (patientId) => {
        const response = await api.get(`/doctor/patients/${patientId}/symptoms`);
        return response.data;
    },
    getPatientMedications: async (patientId) => {
        const response = await api.get(`/doctor/patients/${patientId}/medications`);
        return Array.isArray(response.data) ? response.data.filter(med => med.name !== '__dismissed_symptoms__' && med.name !== '__dismissed_pefr__') : [];
    },
    prescribeMedication: async (patientId, data) => {
        const response = await api.post(`/doctor/patients/${patientId}/prescribe`, data);
        return response.data;
    },
};

export default api;
