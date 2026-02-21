import React, { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { UserPlus, UserCheck, Smartphone, Trash2, Search, Mail } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const StudentsPage = () => {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showAdd, setShowAdd] = useState(false);
    const [newStudent, setNewStudent] = useState({ name: '', email: '' });
    const [search, setSearch] = useState('');

    useEffect(() => {
        fetchStudents();
    }, []);

    const fetchStudents = async () => {
        // Fetch registered students (pending login)
        const { data: registryData } = await supabase
            .from('student_registry')
            .select('*')
            .order('created_at', { ascending: false });

        // Fetch active profiles
        const { data: profileData } = await supabase
            .from('profiles')
            .select('*')
            .eq('role', 'student')
            .order('created_at', { ascending: false });

        // Merge for display
        const merged = [
            ...(registryData || []).map(s => ({ ...s, id: `reg-${s.email}`, status: 'pending' })),
            ...(profileData || []).map(s => ({ ...s, status: 'active' }))
        ];

        setStudents(merged);
        setLoading(false);
    };

    const handleAddStudent = async (e) => {
        e.preventDefault();
        const { error } = await supabase
            .from('student_registry')
            .insert([newStudent]);

        if (!error) {
            fetchStudents();
            setShowAdd(false);
            setNewStudent({ name: '', email: '' });
        } else {
            alert(error.message);
        }
    };

    const unbindDevice = async (id) => {
        if (!confirm('Are you sure you want to unbind this device? The student will need to re-authenticate.')) return;

        const { error } = await supabase
            .from('profiles')
            .update({ device_id: null })
            .eq('id', id);

        if (!error) fetchStudents();
    };

    const filtered = students.filter(s =>
        s.name.toLowerCase().includes(search.toLowerCase()) ||
        s.email.toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div className="page-fade-in">
            <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '48px' }}>
                <div>
                    <h1 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '8px' }}>Student Directory</h1>
                    <p style={{ color: 'var(--text-secondary)' }}>Manage student profiles and hardware associations</p>
                </div>

                <button className="btn-primary" onClick={() => setShowAdd(true)} style={{ borderRadius: '0', background: '#000000', color: '#ffffff', fontWeight: '900', padding: '12px 24px', border: 'none' }}>
                    <UserPlus size={18} style={{ marginRight: '8px' }} /> ADD STUDENT
                </button>
            </header>

            <div style={{ position: 'relative', marginBottom: '32px' }}>
                <Search size={20} style={{ position: 'absolute', left: '16px', top: '14px', color: 'var(--text-muted)' }} />
                <input
                    className="input-field"
                    placeholder="Search by name or email..."
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    style={{ paddingLeft: '52px' }}
                />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '20px' }}>
                <AnimatePresence>
                    {filtered.map(student => (
                        <motion.div
                            key={student.id}
                            layout
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            exit={{ opacity: 0, scale: 0.9 }}
                            style={{
                                padding: '24px',
                                border: '2px solid #000000',
                                background: '#ffffff',
                                boxShadow: '8px 8px 0px #000000'
                            }}
                        >
                            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '20px' }}>
                                <div style={{
                                    width: '48px',
                                    height: '48px',
                                    borderRadius: '0',
                                    background: '#000000',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '20px',
                                    fontWeight: '900',
                                    color: '#ffffff'
                                }}>
                                    {student.name[0]}
                                </div>
                                {student.status === 'pending' ? (
                                    <div style={{
                                        padding: '4px 8px',
                                        borderRadius: '0',
                                        background: '#f0f0f0',
                                        color: '#000000',
                                        fontSize: '10px',
                                        fontWeight: '900',
                                        border: '1px solid #000000'
                                    }}>PENDING LOGIN</div>
                                ) : student.device_id ? (
                                    <div style={{
                                        padding: '6px 12px',
                                        borderRadius: '0',
                                        fontSize: '10px',
                                        fontWeight: '900',
                                        letterSpacing: '0.5px',
                                        background: '#000000',
                                        color: '#ffffff',
                                        border: '1px solid #000000',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '6px'
                                    }}>
                                        <Smartphone size={10} /> DEVICE BOUND
                                    </div>
                                ) : (
                                    <div style={{
                                        padding: '6px 12px',
                                        borderRadius: '0',
                                        fontSize: '10px',
                                        fontWeight: '900',
                                        letterSpacing: '0.5px',
                                        background: '#ffffff',
                                        color: '#000000',
                                        border: '2px dashed #000000',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '6px'
                                    }}>
                                        <Smartphone size={10} style={{ opacity: 0.5 }} /> READY TO BIND
                                    </div>
                                )}
                            </div>

                            <h3 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '4px' }}>{student.name}</h3>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-muted)', fontSize: '14px', marginBottom: '24px' }}>
                                <Mail size={14} /> {student.email}
                            </div>

                            <div style={{ display: 'flex', gap: '12px' }}>
                                {student.device_id && (
                                    <button
                                        className="btn-outline"
                                        onClick={() => unbindDevice(student.id)}
                                        style={{ flex: 1, borderRadius: '0', border: '2px solid #000000', color: '#ff4444', fontWeight: '900', fontSize: '11px' }}
                                    >
                                        UNBIND DEVICE
                                    </button>
                                )}
                                <button className="btn-outline" style={{ minWidth: '42px', padding: '0', borderRadius: '0', border: '2px solid #000000' }}>
                                    <Trash2 size={16} />
                                </button>
                            </div>
                        </motion.div>
                    ))}
                </AnimatePresence>
            </div>

            {/* Add Student Modal */}
            <AnimatePresence>
                {showAdd && (
                    <div style={{
                        position: 'fixed', inset: 0, zIndex: 100,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        background: 'rgba(0,0,0,0.8)', backdropFilter: 'blur(4px)'
                    }}>
                        <motion.div
                            initial={{ opacity: 0, y: 50 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: 50 }}
                            style={{
                                width: '100%',
                                maxWidth: '480px',
                                padding: '40px',
                                background: '#ffffff',
                                border: '4px solid #000000',
                                boxShadow: '16px 16px 0px #000000'
                            }}
                        >
                            <h2 style={{ fontSize: '24px', fontWeight: '800', marginBottom: '8px' }}>Register Student</h2>
                            <p style={{ color: 'var(--text-secondary)', marginBottom: '32px' }}>Initialize a new student profile in the system</p>

                            <form onSubmit={handleAddStudent}>
                                <div style={{ marginBottom: '20px' }}>
                                    <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '8px' }}>FULL NAME</label>
                                    <input
                                        className="input-field"
                                        placeholder="Enter student name"
                                        value={newStudent.name}
                                        onChange={e => setNewStudent({ ...newStudent, name: e.target.value })}
                                        required
                                    />
                                </div>
                                <div style={{ marginBottom: '40px' }}>
                                    <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '8px' }}>EMAIL ADDRESS</label>
                                    <input
                                        type="email"
                                        className="input-field"
                                        placeholder="student@haramaya.com"
                                        value={newStudent.email}
                                        onChange={e => setNewStudent({ ...newStudent, email: e.target.value })}
                                        required
                                    />
                                </div>

                                <div style={{ display: 'flex', gap: '16px' }}>
                                    <button type="button" className="btn-outline" onClick={() => setShowAdd(false)} style={{ flex: 1, borderRadius: '0', border: '2px solid #000000', fontWeight: '900' }}>CANCEL</button>
                                    <button type="submit" className="btn-primary" style={{ flex: 1, borderRadius: '0', background: '#000000', color: '#ffffff', fontWeight: '900', border: 'none' }}>CREATE PROFILE</button>
                                </div>
                            </form>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default StudentsPage;
