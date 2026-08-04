import React, { createContext, useContext, useState, useEffect } from 'react';
import { profileService, authService } from '../services/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [role, setRole] = useState(localStorage.getItem('auth_role') || null);
    const [token, setToken] = useState(localStorage.getItem('auth_token') || null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const initAuth = async () => {
            if (token) {
                try {
                    const profile = await profileService.getProfile();
                    setUser(profile);
                    setRole(profile.role ? profile.role.toLowerCase() : role);
                } catch (error) {
                    console.error("Failed to fetch profile", error);
                    logout();
                }
            }
            setLoading(false);
        };
        initAuth();
    }, [token]);

    const login = async (email, password, selectedRole) => {
        const data = await authService.login(email, password);
        const newRole = data.user_role ? data.user_role.toLowerCase() : 'patient';

        if (selectedRole && newRole !== selectedRole.toLowerCase()) {
            throw new Error(`This account is registered as a ${newRole}. Please select the correct identity.`);
        }

        const newToken = data.access_token;
        localStorage.setItem('auth_token', newToken);
        localStorage.setItem('auth_role', newRole);
        setToken(newToken);
        setRole(newRole);

        // Fetch profile immediately after login
        const profile = await profileService.getProfile();
        setUser(profile);
        return profile;
    };

    const logout = () => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('auth_role');
        setToken(null);
        setRole(null);
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ user, role, token, loading, login, logout, setUser }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
