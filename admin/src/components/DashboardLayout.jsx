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
        fetchLatestExam();

        const subscription = supabase
            .channel('exams-live')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'exams' }, payload => {
                fetchLatestExam();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(subscription);
        };
    }, []);

    const fetchLatestExam = async () => {
        const { data } = await supabase
            .from('exams')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

        if (data) setLatestExam(data);
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
                    padding: '0 12px 40px',
                    overflow: 'hidden'
                }}>
                    <div style={{
                        minWidth: '40px',
                        height: '40px',
                        background: 'var(--accent-indigo)',
                        borderRadius: '10px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                    }}>
                        <Activity color="white" size={24} />
                    </div>
                    {sidebarOpen && (
                        <span style={{ fontSize: '18px', fontWeight: '900', whiteSpace: 'nowrap', textTransform: 'uppercase', letterSpacing: '1px' }}>
                            UniElevate <span style={{ color: '#00d2ff' }}>PRO</span>
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
                                    padding: '12px 16px',
                                    marginBottom: '8px',
                                    borderRadius: '12px',
                                    color: isActive ? 'white' : 'var(--text-secondary)',
                                    background: isActive ? '#000000' : 'transparent',
                                    textDecoration: 'none',
                                    transition: 'all 0.2s ease',
                                    border: isActive ? '1px solid #000000' : '1px solid transparent'
                                }}
                            >
                                <item.icon size={20} style={{ minWidth: '20px', color: isActive ? 'white' : 'inherit' }} />
                                {sidebarOpen && (
                                    <span style={{ marginLeft: '12px', fontSize: '14px', fontWeight: isActive ? '600' : '400' }}>
                                        {item.name}
                                    </span>
                                )}
                            </Link>
                        );
                    })}
                    {sidebarOpen && (
                        <div style={{
                            marginTop: '20px',
                            padding: '16px',
                            background: 'rgba(99, 102, 241, 0.05)',
                            borderRadius: '12px',
                            border: '1px dashed rgba(99, 102, 241, 0.2)'
                        }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px', color: 'var(--text-muted)', fontSize: '11px', fontWeight: '800' }}>
                                <Lock size={12} /> ACTIVE COMMAND
                            </div>
                            <div style={{ fontSize: '16px', fontWeight: '800', color: 'var(--accent-indigo)', letterSpacing: '1px' }}>
                                {latestExam?.access_code || '---'}
                            </div>
                        </div>
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
