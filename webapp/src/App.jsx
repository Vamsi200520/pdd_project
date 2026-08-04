import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';

// Layouts
import MainLayout from './components/layout/MainLayout';

// Auth Pages
import Login from './pages/Login';
import Signup from './pages/Signup';
import ForgotPassword from './pages/ForgotPassword';
import VerifyOtp from './pages/VerifyOtp';

// Patient Pages
import PatientDashboard from './pages/patient/Dashboard';
import GraphPage from './pages/patient/GraphPage';
import SymptomTracker from './pages/patient/SymptomTracker';
import TreatmentPlan from './pages/patient/TreatmentPlan';
import ProfilePage from './pages/shared/ProfilePage';

// Doctor Pages
import DoctorDashboard from './pages/doctor/Dashboard';
import DoctorPatientDetail from './pages/doctor/PatientDetail';

const ProtectedRoute = ({ children, allowedRoles }) => {
  const { token, role, loading } = useAuth();
  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', backgroundColor: '#134e4a' }}>
      <div style={{ width: '40px', height: '40px', border: '4px solid rgba(255,255,255,0.3)', borderTopColor: '#ffffff', borderRadius: '50%' }} className="animate-spin" />
    </div>
  );
  if (!token) return <Navigate to="/login" replace />;
  if (allowedRoles && !allowedRoles.includes(role)) return <Navigate to="/" replace />;
  return children;
};

const RoleBasedRedirect = () => {
  const { role, token, loading } = useAuth();
  if (loading) return null;
  if (!token) return <Navigate to="/login" replace />;
  return <Navigate to={role === 'doctor' ? '/doctor/dashboard' : '/patient/dashboard'} replace />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* ── Public ── */}
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/verify-otp" element={<VerifyOtp />} />
          <Route path="/" element={<RoleBasedRedirect />} />

          {/* ── Patient ── */}
          <Route path="/patient" element={
            <ProtectedRoute allowedRoles={['patient']}>
              <MainLayout />
            </ProtectedRoute>
          }>
            <Route path="dashboard" element={<PatientDashboard />} />
            <Route path="graph" element={<GraphPage />} />
            <Route path="symptom" element={<SymptomTracker />} />
            <Route path="treatment" element={<TreatmentPlan />} />
            <Route path="profile" element={<ProfilePage />} />
          </Route>

          {/* ── Doctor ── */}
          <Route path="/doctor" element={
            <ProtectedRoute allowedRoles={['doctor']}>
              <MainLayout />
            </ProtectedRoute>
          }>
            <Route path="dashboard" element={<DoctorDashboard />} />
            <Route path="patient/:id" element={<DoctorPatientDetail />} />
            <Route path="profile" element={<ProfilePage />} />
          </Route>

          {/* ── Fallback ── */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
