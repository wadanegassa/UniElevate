import React, { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { UserPlus, UserCheck, Smartphone, Trash2, Search, Mail, AlertCircle, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import ConfirmModal from '../components/ConfirmModal';

const StudentsPage = () => {
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showAdd, setShowAdd] = useState(false);
    const [newStudent, setNewStudent] = useState({ name: '', email: '' });
    const [search, setSearch] = useState('');

    // Modal state
    const [modalConfig, setModalConfig] = useState({
        open: false,
        id: null,
        title: '',
        message: '',
        type: 'danger',
        onConfirm: () => { }
    });

    useEffect(() => {
        fetchStudents();
    }, []);

    const fetchStudents = async () => {
        setLoading(true);
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

    const confirmUnbind = (id, name) => {
        setModalConfig({
            open: true,
            id,
            title: 'Unbind Device?',
            message: `Are you sure you want to unbind the device for ${name}? They will be logged out and required to re-authenticate on their next login.`,
            type: 'danger',
            onConfirm: () => unbindDevice(id)
        });
    };

    const confirmDeleteStudent = (student) => {
        setModalConfig({
            open: true,
            id: student.id,
            title: 'Delete Student?',
            message: `Are you sure you want to remove ${student.name} from the system? This will delete their profile and exam results permanently.`,
            type: 'danger',
            onConfirm: () => handleDeleteStudent(student)
        });
    };

    const unbindDevice = async (id) => {
        const { error } = await supabase
            .from('profiles')
            .update({ device_id: null })
            .eq('id', id);

        if (!error) fetchStudents();
        else alert(error.message);
        setModalConfig(prev => ({ ...prev, open: false }));
    };

    const handleDeleteStudent = async (student) => {
        try {
            if (student.status === 'pending') {
                // Delete from registry
                await supabase.from('student_registry').delete().eq('email', student.email);
            } else {
                // Delete from profiles
                await supabase.from('profiles').delete().eq('id', student.id);
            }
            fetchStudents();
        } catch (err) {
            alert(err.message);
        }
        setModalConfig(prev => ({ ...prev, open: false }));
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
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -20 }}
                            style={{
                                padding: '24px',
                                background: '#ffffff',
                                border: '2px solid #000000',
                                boxShadow: student.status === 'active' ? '8px 8px 0px #000000' : 'none',
                                position: 'relative',
                                display: 'flex',
                                flexDirection: 'column',
                                gap: '16px'
                            }}
                        >
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <div style={{
                                    width: '40px',
                                    height: '40px',
                                    background: student.status === 'active' ? '#e1f5fe' : '#f5f5f5',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    borderRadius: '0',
                                    border: '2px solid #000000'
                                }}>
                                    {student.status === 'active' ? <UserCheck size={20} color="#000000" /> : <Mail size={20} color="#000000" />}
                                </div>
                                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                    <span style={{
                                        fontSize: '10px',
                                        fontWeight: '900',
                                        padding: '4px 8px',
                                        background: student.status === 'active' ? '#000000' : '#e5e7eb',
                                        color: student.status === 'active' ? '#ffffff' : '#4b5563',
                                        textTransform: 'uppercase',
                                        letterSpacing: '0.5px'
                                    }}>
                                        {student.status}
                                    </span>
                                    <button
                                        onClick={() => confirmDeleteStudent(student)}
                                        style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', padding: '4px' }}
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>

                            <div>
                                <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '4px' }}>{student.name}</h3>
                                <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>{student.email}</p>
                            </div>

                            {student.status === 'active' && (
                                <div style={{
                                    marginTop: 'auto',
                                    padding: '12px',
                                    background: '#f9fafb',
                                    borderLeft: '4px solid #000000',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'space-between'
                                }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px' }}>
                                        <Smartphone size={14} />
                                        <span style={{ fontWeight: '600' }}>
                                            {student.device_id ? `Bound: ${student.device_id.substring(0, 8)}...` : 'No device bound'}
                                        </span>
                                    </div>
                                    {student.device_id && (
                                        <button
                                            onClick={() => confirmUnbind(student.id, student.name)}
                                            style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: '11px', fontWeight: '800' }}
                                        >
                                            UNBIND
                                        </button>
                                    )}
                                </div>
                            )}
                        </motion.div>
                    ))}
                </AnimatePresence>
            </div>

            {/* Add Student Modal */}
            <AnimatePresence>
                {showAdd && (
                    <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            style={{ background: '#ffffff', padding: '40px', width: '100%', maxWidth: '400px', border: '4px solid #000000', boxShadow: '20px 20px 0px #000000' }}
                        >
                            <h2 style={{ fontSize: '24px', fontWeight: '900', marginBottom: '24px' }}>Register Student</h2>
                            <form onSubmit={handleAddStudent}>
                                <div style={{ marginBottom: '20px' }}>
                                    <label style={{ display: 'block', fontSize: '12px', fontWeight: '700', marginBottom: '8px' }}>FULL NAME</label>
                                    <input
                                        className="input-field"
                                        value={newStudent.name}
                                        onChange={e => setNewStudent({ ...newStudent, name: e.target.value })}
                                        required
                                    />
                                </div>
                                <div style={{ marginBottom: '32px' }}>
                                    <label style={{ display: 'block', fontSize: '12px', fontWeight: '700', marginBottom: '8px' }}>EMAIL ADDRESS</label>
                                    <input
                                        type="email"
                                        className="input-field"
                                        value={newStudent.email}
                                        onChange={e => setNewStudent({ ...newStudent, email: e.target.value })}
                                        required
                                    />
                                </div>
                                <div style={{ display: 'flex', gap: '12px' }}>
                                    <button type="button" onClick={() => setShowAdd(false)} style={{ flex: 1, padding: '12px', background: 'transparent', border: '2px solid #e5e7eb', fontWeight: '800' }}>CANCEL</button>
                                    <button type="submit" style={{ flex: 1, padding: '12px', background: '#000000', color: '#ffffff', fontWeight: '900', border: 'none' }}>REGISTER</button>
                                </div>
                            </form>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            <ConfirmModal
                isOpen={modalConfig.open}
                onClose={() => setModalConfig({ ...modalConfig, open: false })}
                onConfirm={modalConfig.onConfirm}
                title={modalConfig.title}
                message={modalConfig.message}
                type={modalConfig.type}
            />
        </div>
    );
};

export default StudentsPage;
