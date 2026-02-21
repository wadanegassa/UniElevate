import React, { useState } from 'react';
import { supabase } from '../services/supabase';
import { Plus, Trash2, List, FileText, Send, CheckCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const ExamsPage = () => {
    const [exam, setExam] = useState({ title: '', duration: 60, access_code: '' });
    const [questions, setQuestions] = useState([]);
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);

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

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            // 1. Create Exam
            const { data: examData, error: examError } = await supabase
                .from('exams')
                .insert([exam])
                .select()
                .single();

            if (examError) throw examError;

            // 2. Create Questions
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
                            <List size={18} style={{ marginRight: '8px' }} /> ADD MCQ
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
                                className="boxed-question"
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
                                                style={{ fontSize: '13px', background: 'rgba(255,255,255,0.02)' }}
                                            />
                                        ))}
                                        <div style={{ gridColumn: 'span 2' }}>
                                            <input
                                                className="input-field"
                                                placeholder="Correct Answer (Exact text match)"
                                                value={q.correct_answer}
                                                onChange={e => updateQuestion(index, 'correct_answer', e.target.value)}
                                                required
                                                style={{ borderBottom: '1px solid rgba(34, 197, 94, 0.3)' }}
                                            />
                                        </div>
                                    </div>
                                ) : (
                                    <div>
                                        <label style={{ display: 'block', fontSize: '11px', color: 'var(--text-muted)', marginBottom: '8px' }}>KEYWORDS (COMMA SEPARATED)</label>
                                        <input
                                            className="input-field"
                                            placeholder="e.g. photosynthesis, chlorophyll, sunlight"
                                            value={q.keywords.join(', ')}
                                            onChange={e => updateQuestion(index, 'keywords', e.target.value.split(',').map(k => k.trim()))}
                                            required
                                        />
                                    </div>
                                )}
                            </motion.div>
                        ))}
                    </AnimatePresence>
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                    <button type="submit" className="btn-primary" disabled={loading || questions.length === 0} style={{ padding: '16px 48px', borderRadius: '0', background: '#000000', color: '#ffffff', fontWeight: '900', letterSpacing: '1px', border: 'none' }}>
                        {loading ? 'DEPLOYING...' : success ? <CheckCircle /> : <><Send size={20} style={{ marginRight: '10px' }} /> DEPLOY EXAM</>}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default ExamsPage;
