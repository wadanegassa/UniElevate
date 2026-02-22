import React, { useState, useEffect } from 'react';
import { supabase } from '../services/supabase';
import { Plus, Trash2, List, FileText, Send, CheckCircle, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import ConfirmModal from '../components/ConfirmModal';

const ExamsPage = () => {
    const [exam, setExam] = useState({ title: '', duration: 60, access_code: '' });
    const [questions, setQuestions] = useState([]);
    const [existingExams, setExistingExams] = useState([]);
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);

    // Modal states
    const [modalConfig, setModalConfig] = useState({ open: false, id: null, title: '', message: '', type: 'danger', onConfirm: () => { } });

    useEffect(() => {
        fetchExams();
    }, []);

    const fetchExams = async () => {
        const { data } = await supabase
            .from('exams')
            .select('*')
            .order('created_at', { ascending: false });
        if (data) setExistingExams(data);
    };

    const addQuestion = (type) => {
        setQuestions([...questions, {
            text: '',
            type,
            options: type === 'MCQ' ? ['', '', '', ''] : null,
            correct_answer: '',
            keywords: type === 'Theory' ? [] : null
        }]);
    };

    const removeQuestion = (index) => {
        setQuestions(questions.filter((_, i) => i !== index));
    };

    const updateQuestion = (index, field, value) => {
        const updated = [...questions];
        updated[index][field] = value;
        setQuestions(updated);
    };

    const updateOption = (qIndex, oIndex, value) => {
        const updated = [...questions];
        updated[qIndex].options[oIndex] = value;
        setQuestions(updated);
    };

    const handleActivate = async (id) => {
        setLoading(true);
        try {
            await supabase.from('exams').update({ is_active: false }).neq('id', id);
            const { error } = await supabase.from('exams').update({ is_active: true }).eq('id', id);
            if (error) throw error;

            setTimeout(() => {
                fetchExams();
                setLoading(false);
            }, 400);
        } catch (err) {
            alert(err.message);
            setLoading(false);
        }
    };

    const handleDeactivate = async (id) => {
        setLoading(true);
        try {
            const { error } = await supabase.from('exams').update({ is_active: false }).eq('id', id);
            if (error) throw error;
            fetchExams();
        } catch (err) {
            alert(err.message);
        } finally {
            setLoading(false);
        }
    };

    const confirmDelete = (id, title) => {
        setModalConfig({
            open: true,
            id,
            title: 'Delete Exam?',
            message: `Are you sure you want to delete "${title}"? All associated questions and student results will be permanently lost.`,
            type: 'danger',
            onConfirm: () => handleDelete(id)
        });
    };

    const handleDelete = async (id) => {
        setLoading(true);
        const { error } = await supabase.from('exams').delete().eq('id', id);
        if (!error) {
            fetchExams();
            setModalConfig(prev => ({ ...prev, open: false }));
        } else {
            alert(error.message);
        }
        setLoading(false);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const { data: examData, error: examError } = await supabase
                .from('exams')
                .insert([exam])
                .select()
                .single();

            if (examError) throw examError;

            const questionsWithId = questions.map(q => ({
                ...q,
                exam_id: examData.id
            }));

            const { error: qError } = await supabase
                .from('questions')
                .insert(questionsWithId);

            if (qError) throw qError;

            setSuccess(true);
            setExam({ title: '', duration: 60, access_code: '' });
            setQuestions([]);
            fetchExams();
            setTimeout(() => setSuccess(false), 3000);
        } catch (err) {
            alert(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="page-fade-in">
            <header style={{ marginBottom: '48px' }}>
                <h1 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '8px' }}>Create New Exam</h1>
                <p style={{ color: 'var(--text-secondary)' }}>Design and deploy assessments to the student portal</p>
            </header>

            <form onSubmit={handleSubmit}>
                <div style={{
                    padding: '32px',
                    marginBottom: '32px',
                    border: '2px solid #000000',
                    background: '#ffffff',
                    boxShadow: '12px 12px 0px #000000'
                }}>
                    <h2 style={{ fontSize: '18px', fontWeight: '900', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px', textTransform: 'uppercase' }}>
                        <FileText size={20} color="#000000" /> Exam Details
                    </h2>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                        <div>
                            <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: 'var(--text-muted)', marginBottom: '8px' }}>EXAM TITLE</label>
                            <input
                                className="input-field"
                                placeholder="Final Examination 2026"
                                value={exam.title}
                                onChange={e => setExam({ ...exam, title: e.target.value })}
                                required
                            />
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                            <div>
                                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: 'var(--text-muted)', marginBottom: '8px' }}>DURATION (MIN)</label>
                                <input
                                    type="number"
                                    className="input-field"
                                    placeholder="60"
                                    value={exam.duration}
                                    onChange={e => setExam({ ...exam, duration: parseInt(e.target.value) })}
                                    required
                                />
                            </div>
                            <div>
                                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: 'var(--text-muted)', marginBottom: '8px' }}>ACCESS COMMAND</label>
                                <input
                                    className="input-field"
                                    placeholder="START_NOW"
                                    value={exam.access_code}
                                    onChange={e => setExam({ ...exam, access_code: e.target.value })}
                                    required
                                />
                            </div>
                        </div>
                    </div>
                </div>

                <div style={{ marginBottom: '32px' }}>
                    <h2 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '16px' }}>Questions</h2>

                    <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
                        <button type="button" className="btn-outline" onClick={() => addQuestion('MCQ')} style={{ flex: 1, borderRadius: '0', border: '2px solid #000000', fontWeight: '900', background: '#ffffff', color: '#000000' }}>
                            <Plus size={18} style={{ marginRight: '8px' }} /> ADD MCQ
                        </button>
                        <button type="button" className="btn-outline" onClick={() => addQuestion('Theory')} style={{ flex: 1, borderRadius: '0', border: '2px solid #000000', fontWeight: '900', background: '#ffffff', color: '#000000' }}>
                            <FileText size={18} style={{ marginRight: '8px' }} /> ADD THEORY
                        </button>
                    </div>

                    <AnimatePresence>
                        {questions.map((q, index) => (
                            <motion.div
                                key={index}
                                initial={{ opacity: 0, scale: 0.95 }}
                                animate={{ opacity: 1, scale: 1 }}
                                exit={{ opacity: 0, scale: 0.95 }}
                                style={{
                                    padding: '24px',
                                    marginBottom: '24px',
                                    border: '2px solid #000000',
                                    background: '#ffffff',
                                    boxShadow: '8px 8px 0px #000000'
                                }}
                            >
                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
                                    <span style={{ fontSize: '12px', fontWeight: '900', color: '#000000', letterSpacing: '1px', textTransform: 'uppercase' }}>
                                        #{index + 1} {q.type} QUESTION
                                    </span>
                                    <button type="button" onClick={() => removeQuestion(index)} style={{ background: 'transparent', border: 'none', color: '#f87171', cursor: 'pointer' }}>
                                        <Trash2 size={18} />
                                    </button>
                                </div>

                                <input
                                    className="input-field"
                                    placeholder="Enter question text..."
                                    value={q.text}
                                    onChange={e => updateQuestion(index, 'text', e.target.value)}
                                    required
                                    style={{ marginBottom: '20px', fontSize: '16px' }}
                                />

                                {q.type === 'MCQ' ? (
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                                        {q.options.map((opt, oi) => (
                                            <input
                                                key={oi}
                                                className="input-field"
                                                placeholder={`Option ${oi + 1}`}
                                                value={opt}
                                                onChange={e => updateOption(index, oi, e.target.value)}
                                                required
                                                style={{ fontSize: '13px' }}
                                            />
                                        ))}
                                        <div style={{ gridColumn: 'span 2' }}>
                                            <input
                                                className="input-field"
                                                placeholder="Correct Answer (Exact text match)"
                                                value={q.correct_answer}
                                                onChange={e => updateQuestion(index, 'correct_answer', e.target.value)}
                                                required
                                                style={{ borderBottom: '2px solid #000000' }}
                                            />
                                        </div>
                                    </div>
                                ) : (
                                    <div>
                                        <label style={{ display: 'block', fontSize: '11px', color: 'var(--text-muted)', marginBottom: '8px' }}>KEYWORDS (COMMA SEPARATED)</label>
                                        <input
                                            className="input-field"
                                            placeholder="e.g. photosynthesis, chlorophyll, sunlight"
                                            value={q.keywords?.join(', ') || ''}
                                            onChange={e => updateQuestion(index, 'keywords', e.target.value.split(',').map(k => k.trim()))}
                                            required
                                        />
                                    </div>
                                )}
                            </motion.div>
                        ))}
                    </AnimatePresence>
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '64px' }}>
                    <button type="submit" className="btn-primary" disabled={loading || questions.length === 0} style={{ padding: '16px 48px', borderRadius: '0', background: '#000000', color: '#ffffff', fontWeight: '900', letterSpacing: '1px', border: 'none' }}>
                        {loading ? 'DEPLOYING...' : success ? <CheckCircle /> : <><Send size={20} style={{ marginRight: '10px' }} /> DEPLOY EXAM</>}
                    </button>
                </div>
            </form>

            <section style={{ marginTop: '80px' }}>
                <h2 style={{ fontSize: '24px', fontWeight: '900', marginBottom: '32px', textTransform: 'uppercase', letterSpacing: '1px' }}>Manage Existing Exams</h2>

                <div style={{ display: 'grid', gap: '20px' }}>
                    {existingExams.map(ex => (
                        <motion.div
                            key={ex.id}
                            layout
                            style={{
                                padding: '24px',
                                background: '#ffffff',
                                border: ex.is_active ? '4px solid #6366f1' : '2px solid #000000',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                boxShadow: ex.is_active ? '12px 12px 0px #6366f1' : '8px 8px 0px #000000',
                                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
                            }}
                        >
                            <div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                                    <h3 style={{ fontSize: '18px', fontWeight: '800' }}>{ex.title}</h3>
                                    {ex.is_active && (
                                        <motion.span
                                            initial={{ scale: 0.8 }}
                                            animate={{ scale: 1 }}
                                            style={{
                                                padding: '4px 12px',
                                                background: '#6366f1',
                                                color: '#ffffff',
                                                fontSize: '11px',
                                                fontWeight: '950',
                                                textTransform: 'uppercase',
                                                letterSpacing: '0.5px'
                                            }}
                                        >
                                            ACTIVE
                                        </motion.span>
                                    )}
                                </div>
                                <div style={{ display: 'flex', gap: '24px', fontSize: '14px', color: 'var(--text-secondary)' }}>
                                    <span>Duration: <strong>{ex.duration}m</strong></span>
                                    <span>Command: <strong style={{ color: '#6366f1', letterSpacing: '1px' }}>{ex.access_code}</strong></span>
                                </div>
                            </div>

                            <div style={{ display: 'flex', gap: '16px' }}>
                                {!ex.is_active ? (
                                    <button
                                        onClick={() => handleActivate(ex.id)}
                                        style={{
                                            padding: '10px 20px',
                                            borderRadius: '0',
                                            border: '2px solid #000000',
                                            fontWeight: '900',
                                            fontSize: '12px',
                                            background: '#ffffff',
                                            cursor: 'pointer'
                                        }}
                                    >
                                        ACTIVATE
                                    </button>
                                ) : (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                        <span style={{ color: '#6366f1', display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', fontWeight: '800' }}>
                                            <CheckCircle size={14} /> LIVE
                                        </span>
                                        <button
                                            onClick={() => handleDeactivate(ex.id)}
                                            style={{
                                                padding: '8px 16px',
                                                borderRadius: '0',
                                                border: '2px solid #ef4444',
                                                color: '#ef4444',
                                                fontWeight: '900',
                                                fontSize: '11px',
                                                background: 'transparent',
                                                cursor: 'pointer'
                                            }}
                                        >
                                            DEACTIVATE
                                        </button>
                                    </div>
                                )}
                                <button
                                    onClick={() => confirmDelete(ex.id, ex.title)}
                                    style={{ padding: '8px', color: '#ef4444', background: 'transparent', border: 'none', cursor: 'pointer' }}
                                >
                                    <Trash2 size={20} />
                                </button>
                            </div>
                        </motion.div>
                    ))}
                    {existingExams.length === 0 && (
                        <div style={{ padding: '48px', textAlign: 'center', border: '2px dashed #e5e7eb', color: 'var(--text-muted)' }}>
                            No exams created yet.
                        </div>
                    )}
                </div>
            </section>

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

export default ExamsPage;
