import React, { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { patientService } from '../../services/api';
import {
    LayoutDashboard, LineChart, ClipboardList, Pill, User,
    LogOut, Wind, ChevronRight, Bell, Users, X
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import logo from '../../assets/logo.png';

const SIDEBAR_OPEN_W = 270;
const SIDEBAR_CLOSE_W = 72;
const HEADER_H = 70;

const MainLayout = () => {
    const { user, logout, role } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const [open, setOpen] = useState(true);
    const [notifications, setNotifications] = useState([]);
    const [showNotifications, setShowNotifications] = useState(false);

    useEffect(() => {
        // Fetch notifications every 30s
        const fetchNotifs = async () => {
            try {
                const data = await patientService.getNotifications();
                setNotifications(Array.isArray(data) ? data : []);
            } catch (err) {
                // Ignore silent fail
            }
        };
        fetchNotifs();
        const int = setInterval(fetchNotifs, 30000);
        return () => clearInterval(int);
    }, []);

    const handleReadNotification = async (id) => {
        try {
            await patientService.markNotificationRead(id);
            setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
        } catch (err) { }
    };

    const displayName = user?.name || user?.fullName || 'Account';
    const initial = displayName.charAt(0).toUpperCase();
    const sidebarW = open ? SIDEBAR_OPEN_W : SIDEBAR_CLOSE_W;
    const unreadCount = notifications.filter(n => !n.is_read).length;

    const navItems = role === 'doctor' ? [
        { path: '/doctor/dashboard', label: 'Patient Management', icon: Users },
        { path: '/doctor/profile', label: 'Doctor Profile', icon: User },
    ] : [
        { path: '/patient/dashboard', label: 'Home Dashboard', icon: LayoutDashboard },
        { path: '/patient/graph', label: 'PPC Clinical Chart', icon: LineChart },
        { path: '/patient/symptom', label: 'Symptom Tracker', icon: ClipboardList },
        { path: '/patient/treatment', label: 'Treatment Plan', icon: Pill },
        { path: '/patient/profile', label: 'My Profile', icon: User },
    ];

    const isActive = (path) => location.pathname === path || (path !== '/doctor/dashboard' && location.pathname.startsWith(path.replace('/dashboard', '')));

    const navBtn = (active) => ({
        display: 'flex', alignItems: 'center', gap: '0.85rem', padding: '0.8rem 1rem', width: '100%', margin: '2px 0',
        borderRadius: '12px', border: 'none', backgroundColor: active ? 'rgba(255,255,255,0.15)' : 'transparent',
        color: active ? '#ffffff' : 'rgba(255,255,255,0.55)', cursor: 'pointer', fontWeight: active ? '800' : '600',
        fontSize: '0.9rem', transition: 'all 0.18s', textAlign: 'left', whiteSpace: 'nowrap', overflow: 'hidden'
    });

    return (
        <div style={{ display: 'flex', backgroundColor: '#f1f5f9', minHeight: '100vh' }}>
            <aside style={{ width: sidebarW, minWidth: sidebarW, backgroundColor: '#134e4a', height: '100vh', position: 'fixed', left: 0, top: 0, transition: 'width 0.28s ease', display: 'flex', flexDirection: 'column', zIndex: 100, boxShadow: '4px 0 20px rgba(0,0,0,0.12)', overflow: 'hidden' }}>
                <div onClick={() => setOpen(o => !o)} style={{ padding: '1.5rem 1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
                    <div style={{ padding: '0.2rem', backgroundColor: '#ffffff', borderRadius: '10px', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <img src={logo} alt="icon" style={{ width: '28px', height: '28px', borderRadius: '6px' }} />
                    </div>
                    {open && <span style={{ fontSize: '1.1rem', fontWeight: '900', color: '#ffffff', letterSpacing: '0.1em' }}>PEFR</span>}
                </div>
                {open && <div style={{ padding: '1rem 1.25rem 0.5rem', fontSize: '0.68rem', fontWeight: '900', color: 'rgba(255,255,255,0.4)', letterSpacing: '0.12em', textTransform: 'uppercase' }}>{role === 'doctor' ? 'Clinical Portal' : 'Patient Portal'}</div>}
                <nav style={{ flex: 1, padding: '0.5rem 0.75rem', overflowY: 'auto' }}>
                    {navItems.map((item) => {
                        const active = isActive(item.path);
                        const Icon = item.icon;
                        return (
                            <button key={item.path} onClick={() => navigate(item.path)} style={navBtn(active)} onMouseEnter={e => { if (!active) e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.08)' }} onMouseLeave={e => { if (!active) e.currentTarget.style.backgroundColor = 'transparent' }}>
                                <Icon size={20} style={{ flexShrink: 0 }} />
                                {open && <span style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis' }}>{item.label}</span>}
                                {active && open && <ChevronRight size={15} style={{ flexShrink: 0, opacity: 0.7 }} />}
                            </button>
                        );
                    })}
                </nav>
                <div style={{ padding: '0.75rem', borderTop: '1px solid rgba(255,255,255,0.08)' }}>
                    <button onClick={logout} style={{ ...navBtn(false), color: '#fda4af' }} onMouseEnter={e => e.currentTarget.style.backgroundColor = 'rgba(239,68,68,0.15)'} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
                        <LogOut size={20} style={{ flexShrink: 0 }} />{open && <span>Secure Logout</span>}
                    </button>
                </div>
            </aside>

            <header style={{ height: HEADER_H, backgroundColor: '#ffffff', borderBottom: '1px solid #e2e8f0', position: 'fixed', top: 0, left: sidebarW, right: 0, transition: 'left 0.28s ease', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 2rem', zIndex: 90, boxSizing: 'border-box' }}>
                <div style={{ fontWeight: '900', fontSize: '1.1rem', color: '#0f172a' }}>
                    {navItems.find(n => location.pathname.startsWith(n.path.replace('/dashboard', '')))?.label || (location.pathname.includes('/patient/') ? 'Patient Details' : 'Clinical Portal')}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', position: 'relative' }}>

                    {/* NOTIFICATIONS */}
                    <button onClick={() => setShowNotifications(s => !s)} style={{ background: 'none', border: 'none', color: '#64748b', position: 'relative', cursor: 'pointer', padding: '0.5rem' }}>
                        <Bell size={22} />
                        {unreadCount > 0 && <span style={{ position: 'absolute', top: '4px', right: '4px', width: '10px', height: '10px', backgroundColor: '#ef4444', borderRadius: '50%', border: '2px solid #ffffff' }} />}
                    </button>

                    <AnimatePresence>
                        {showNotifications && (
                            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 10 }}
                                style={{ position: 'absolute', top: '100%', right: '1rem', width: '320px', backgroundColor: '#fff', borderRadius: '1.25rem', boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15)', border: '1px solid #e2e8f0', marginTop: '0.5rem', overflow: 'hidden' }}>
                                <div style={{ padding: '1rem', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <span style={{ fontWeight: '900', color: '#0f172a' }}>Notifications</span>
                                    <button onClick={() => setShowNotifications(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8' }}><X size={16} /></button>
                                </div>
                                <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
                                    {notifications.length === 0 ? (
                                        <div style={{ padding: '2rem', textAlign: 'center', color: '#94a3b8', fontSize: '0.85rem', fontWeight: '600' }}>No notifications</div>
                                    ) : (
                                        notifications.map(n => (
                                            <div key={n.id} onClick={() => handleReadNotification(n.id)} style={{ padding: '1rem', borderBottom: '1px solid #f1f5f9', cursor: 'pointer', backgroundColor: n.is_read ? '#fff' : '#f8fafc' }}>
                                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                                                    <span style={{ fontWeight: '800', fontSize: '0.85rem', color: '#0f172a' }}>{n.title}</span>
                                                    {!n.is_read && <span style={{ width: '8px', height: '8px', backgroundColor: '#ef4444', borderRadius: '50%' }} />}
                                                </div>
                                                <p style={{ margin: 0, fontSize: '0.8rem', color: '#64748b', lineHeight: 1.4 }}>{n.message}</p>
                                                <div style={{ fontSize: '0.7rem', color: '#cbd5e1', fontWeight: '700', marginTop: '0.5rem' }}>{new Date(n.created_at || Date.now()).toLocaleString()}</div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </motion.div>
                        )}
                    </AnimatePresence>

                    {/* USER BADGE */}
                    <div onClick={() => navigate(role === 'doctor' ? '/doctor/profile' : '/patient/profile')} style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', paddingLeft: '1.25rem', borderLeft: '1px solid #e2e8f0', cursor: 'pointer' }}>
                        <div style={{ textAlign: 'right' }}>
                            <div style={{ fontSize: '0.88rem', fontWeight: '800', color: '#0f172a', lineHeight: 1.3 }}>{displayName}</div>
                            <div style={{ fontSize: '0.7rem', fontWeight: '700', color: '#4db6ac', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{role} PORTAL</div>
                        </div>
                        <div style={{ width: '42px', height: '42px', backgroundColor: '#134e4a', color: '#ffffff', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.1rem', fontWeight: '900', flexShrink: 0 }}>{initial}</div>
                    </div>
                </div>
            </header>

            <main style={{ flex: 1, marginLeft: sidebarW, marginTop: HEADER_H, padding: '2.5rem 3rem', transition: 'margin-left 0.28s ease', minHeight: `calc(100vh - ${HEADER_H}px)`, boxSizing: 'border-box', overflowX: 'hidden' }}>
                <Outlet />
            </main>
        </div>
    );
};

export default MainLayout;
