import React, { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../services/supabase';
import {
    Activity,
    PlusCircle,
    Users,
    LogOut,
    ChevronRight,
    Menu,
    X,
    Lock
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const DashboardLayout = () => {
    const { logout, user } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();
    const [sidebarOpen, setSidebarOpen] = useState(true);
    const [latestExam, setLatestExam] = useState(null);

    useEffect(() => {
        fetchActiveExam();

        const subscription = supabase
            .channel('exams-live')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'exams' }, payload => {
                fetchActiveExam();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(subscription);
        };
    }, []);

    const fetchActiveExam = async () => {
        try {
            const { data, error } = await supabase
                .from('exams')
                .select('*')
                .eq('is_active', true)
                .maybeSingle();

            if (error) {
                console.error('Error fetching active exam:', error);
                setLatestExam(null);
                return;
            }

            // Explicitly set to null if no active exam is found
            if (!data) {
                setLatestExam(null);
            } else {
                setLatestExam(data);
            }
        } catch (err) {
            console.error('Unexpected error in fetchActiveExam:', err);
            setLatestExam(null);
        }
    };

    const menuItems = [
        { name: 'Live Monitor', icon: Activity, path: '/' },
        { name: 'Create Exam', icon: PlusCircle, path: '/exams' },
        { name: 'Students', icon: Users, path: '/students' },
    ];

    return (
        <div style={{ display: 'flex', height: '100vh', background: 'var(--bg-primary)' }}>
            {/* Sidebar */}
            <motion.aside
                initial={false}
                animate={{ width: sidebarOpen ? '280px' : '80px' }}
                style={{
                    background: 'var(--bg-secondary)',
                    borderRight: '1px solid var(--border-subtle)',
                    display: 'flex',
                    flexDirection: 'column',
                    transition: 'width 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    position: 'relative',
                    padding: '24px 16px'
                }}
            >
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '0 12px 48px',
                    overflow: 'hidden'
                }}>
                    <div style={{
                        minWidth: '40px',
                        height: '40px',
                        background: '#000000',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        border: '2px solid #000000',
                        boxShadow: '4px 4px 0px #6366f1'
                    }}>
                        <Activity color="white" size={24} />
                    </div>
                    {sidebarOpen && (
                        <span style={{ fontSize: '18px', fontWeight: '950', whiteSpace: 'nowrap', textTransform: 'uppercase', letterSpacing: '1.5px', color: '#000000' }}>
                            UNIELEVATE <span style={{ color: '#6366f1' }}>PRO</span>
                        </span>
                    )}
                </div>

                <nav style={{ flex: 1 }}>
                    {menuItems.map((item) => {
                        const isActive = location.pathname === item.path;
                        return (
                            <Link
                                key={item.name}
                                to={item.path}
                                style={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    padding: '14px 16px',
                                    marginBottom: '12px',
                                    color: isActive ? 'white' : '#000000',
                                    background: isActive ? '#000000' : 'transparent',
                                    textDecoration: 'none',
                                    transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                                    border: isActive ? '2px solid #000000' : '2px solid transparent',
                                    fontWeight: '900',
                                    textTransform: 'uppercase',
                                    letterSpacing: '0.5px',
                                    fontSize: '12px'
                                }}
                            >
                                <item.icon size={18} style={{ minWidth: '18px', color: isActive ? 'white' : '#000000' }} />
                                {sidebarOpen && (
                                    <span style={{ marginLeft: '16px' }}>
                                        {item.name}
                                    </span>
                                )}
                            </Link>
                        );
                    })}
                    {sidebarOpen && (
                        <motion.div
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            style={{
                                marginTop: '40px',
                                padding: '24px',
                                background: latestExam ? '#6366f1' : '#1f2937',
                                color: '#ffffff',
                                border: '3px solid #000000',
                                boxShadow: '8px 8px 0px #000000',
                                position: 'relative',
                                overflow: 'hidden',
                                transition: 'background 0.3s ease'
                            }}
                        >
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                                <label style={{ fontSize: '10px', fontWeight: '950', color: 'rgba(255,255,255,0.7)', letterSpacing: '1px', textTransform: 'uppercase' }}>
                                    {latestExam ? 'LIVE PROCTOR ACCESS' : 'SYSTEM OFFLINE'}
                                </label>
                                {latestExam && (
                                    <motion.div
                                        animate={{ opacity: [1, 0.4, 1] }}
                                        transition={{ repeat: Infinity, duration: 1.5 }}
                                        style={{ width: '8px', height: '8px', background: '#4ade80', borderRadius: '50%' }}
                                    />
                                )}
                            </div>

                            <div style={{ marginBottom: '4px', fontSize: '11px', fontWeight: '800', opacity: 0.9, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                {latestExam?.title || 'No Exam Active'}
                            </div>

                            <div style={{ fontSize: '24px', fontWeight: '950', letterSpacing: '2px', fontFamily: 'monospace', textShadow: '2px 2px 0px rgba(0,0,0,0.2)' }}>
                                {latestExam?.access_code || '---'}
                            </div>

                            <div style={{
                                position: 'absolute',
                                right: '-10px',
                                bottom: '-10px',
                                opacity: 0.1
                            }}>
                                <Lock size={64} />
                            </div>
                        </motion.div>
                    )}
                </nav>

                <div style={{ paddingTop: '20px', borderTop: '1px solid var(--border-subtle)' }}>
                    <button
                        onClick={logout}
                        style={{
                            width: '100%',
                            display: 'flex',
                            alignItems: 'center',
                            padding: '12px 16px',
                            borderRadius: '12px',
                            color: 'rgba(239, 68, 68, 0.7)',
                            background: 'transparent',
                            border: 'none',
                            cursor: 'pointer',
                            transition: 'all 0.2s ease'
                        }}
                    >
                        <LogOut size={20} style={{ minWidth: '20px' }} />
                        {sidebarOpen && <span style={{ marginLeft: '12px', fontSize: '14px' }}>Logout</span>}
                    </button>
                </div>

                {/* Toggle Button */}
                <button
                    onClick={() => setSidebarOpen(!sidebarOpen)}
                    style={{
                        position: 'absolute',
                        right: '-16px',
                        top: '32px',
                        width: '32px',
                        height: '32px',
                        borderRadius: '50%',
                        background: 'var(--bg-tertiary)',
                        border: '1px solid var(--border-subtle)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'pointer',
                        color: 'white',
                        zIndex: 10
                    }}
                >
                    {sidebarOpen ? <X size={14} /> : <Menu size={14} />}
                </button>
            </motion.aside>

            {/* Main Content */}
            <main style={{
                flex: 1,
                overflowY: 'auto',
                padding: '40px',
                background: '#ffffff'
            }}>
                <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
                    <Outlet />
                </div>
            </main>
        </div>
    );
};

export default DashboardLayout;
