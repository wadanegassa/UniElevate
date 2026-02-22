import React, { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { ChevronDown, ChevronUp, User, BookOpen, Activity } from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';

const MonitoringPage = () => {
    const [answers, setAnswers] = useState([]);
    const [exams, setExams] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedExamId, setSelectedExamId] = useState(null);
    const [expandedStudentId, setExpandedStudentId] = useState(null);

    useEffect(() => {
        fetchHistory();
        fetchExams();

        const answersSub = supabase
            .channel('answers-live')
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'answers' }, async payload => {
                const { data: profile } = await supabase
                    .from('profiles')
                    .select('email, name')
                    .eq('id', payload.new.student_id)
                    .maybeSingle();

                const newAnswerWithProfile = { ...payload.new, profiles: profile };
                setAnswers(prev => [newAnswerWithProfile, ...prev]);
            })
            .subscribe();

        const examsSub = supabase
            .channel('exams-live')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'exams' }, payload => {
                fetchExams();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(answersSub);
            supabase.removeChannel(examsSub);
        };
    }, []);

    const fetchHistory = async () => {
        const { data } = await supabase
            .from('answers')
            .select('*, profiles(email, name)')
            .order('timestamp', { ascending: false })
            .limit(50);
        if (data) setAnswers(data);
    };

    const fetchExams = async () => {
        const { data } = await supabase
            .from('exams')
            .select('*, questions(*)')
            .order('created_at', { ascending: false });

        if (data) {
            setExams(data);
            if (data.length > 0 && !selectedExamId) {
                setSelectedExamId(data[0].id);
            }
        }
        setLoading(false);
    };

    // Group answers by Exam and then by Student
    const answersByExam = answers.reduce((acc, ans) => {
        if (!acc[ans.exam_id]) acc[ans.exam_id] = {};
        if (!acc[ans.exam_id][ans.student_id]) {
            acc[ans.exam_id][ans.student_id] = {
                profile: ans.profiles,
                totalScore: 0,
                responses: []
            };
        }
        acc[ans.exam_id][ans.student_id].responses.push(ans);
        acc[ans.exam_id][ans.student_id].totalScore += ans.score;
        return acc;
    }, {});

    const activeExam = exams.find(e => e.id === selectedExamId);
    const activeStudents = selectedExamId && answersByExam[selectedExamId]
        ? Object.entries(answersByExam[selectedExamId])
        : [];

    return (
        <div className="page-fade-in">
            <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '48px' }}>
                <div>
                    <h1 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '8px' }}>Live Monitoring</h1>
                    <p style={{ color: 'var(--text-secondary)' }}>Real-time student responses and AI grading stream</p>
                </div>

                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    background: '#000000',
                    padding: '8px 16px',
                    borderRadius: '0',
                    border: '1px solid #000000'
                }}>
                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#00d2ff', animation: 'pulse 2s infinite' }}></div>
                    <span style={{ fontSize: '11px', fontWeight: '900', color: '#ffffff', letterSpacing: '1px' }}>LIVE FEED</span>
                </div>
            </header>

            {/* Exam Selector */}
            <section style={{ marginBottom: '32px' }}>
                <h2 style={{ fontSize: '14px', fontWeight: '900', marginBottom: '16px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>
                    Active Exams
                </h2>
                <div style={{ display: 'flex', gap: '12px', overflowX: 'auto', paddingBottom: '16px' }}>
                    {exams.map(ex => (
                        <button
                            key={ex.id}
                            onClick={() => setSelectedExamId(ex.id)}
                            style={{
                                padding: '16px 24px',
                                border: '2px solid #000000',
                                background: selectedExamId === ex.id ? '#000000' : '#ffffff',
                                color: selectedExamId === ex.id ? '#ffffff' : '#000000',
                                boxShadow: selectedExamId === ex.id ? '4px 4px 0px var(--accent-indigo)' : '4px 4px 0px #000000',
                                cursor: 'pointer',
                                textAlign: 'left',
                                minWidth: '250px',
                                transition: 'all 0.2s ease',
                                transform: selectedExamId === ex.id ? 'translateY(2px)' : 'none'
                            }}
                        >
                            <div style={{ fontSize: '10px', fontWeight: '900', color: selectedExamId === ex.id ? '#a5b4fc' : 'var(--text-muted)', marginBottom: '4px' }}>
                                {ex.access_code}
                            </div>
                            <h3 style={{ fontSize: '16px', fontWeight: '800', textTransform: 'uppercase' }}>{ex.title}</h3>
                        </button>
                    ))}
                    {exams.length === 0 && !loading && (
                        <p style={{ color: 'var(--text-muted)' }}>No exams deployed.</p>
                    )}
                </div>
            </section>

            {/* Student Dashboard for Selected Exam */}
            {activeExam && (
                <div style={{ border: '2px solid #000000', background: '#ffffff', boxShadow: '8px 8px 0px #000000' }}>
                    <div style={{ padding: '24px', borderBottom: '2px solid #000000', background: '#f8f8f8', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <BookOpen size={20} />
                            <h2 style={{ fontSize: '18px', fontWeight: '900', textTransform: 'uppercase' }}>Student Progress: {activeExam.title}</h2>
                        </div>
                        <span style={{ fontSize: '12px', fontWeight: '800', background: '#000000', color: '#ffffff', padding: '4px 12px' }}>
                            {activeStudents.length} Students Active
                        </span>
                    </div>

                    <div>
                        {activeStudents.length === 0 ? (
                            <div style={{ padding: '64px', textAlign: 'center', color: 'var(--text-muted)' }}>
                                <Activity size={48} style={{ opacity: 0.1, margin: '0 auto 16px' }} />
                                <p style={{ fontWeight: '600' }}>Waiting for student submissions on this exam...</p>
                            </div>
                        ) : (
                            activeStudents.map(([studentId, data], ix) => {
                                const isExpanded = expandedStudentId === studentId;
                                const email = data.profile?.email || studentId.substring(0, 8);

                                return (
                                    <div key={studentId} style={{ borderBottom: ix < activeStudents.length - 1 ? '1px solid #e5e7eb' : 'none' }}>
                                        {/* Student Row */}
                                        <button
                                            onClick={() => setExpandedStudentId(isExpanded ? null : studentId)}
                                            style={{
                                                width: '100%',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'space-between',
                                                padding: '20px 24px',
                                                background: isExpanded ? '#f5f3ff' : 'transparent',
                                                border: 'none',
                                                cursor: 'pointer',
                                                textAlign: 'left',
                                                transition: 'background 0.2s ease'
                                            }}
                                        >
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                                                <div style={{ width: '40px', height: '40px', background: '#000000', color: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '900', fontSize: '14px' }}>
                                                    {email.charAt(0).toUpperCase()}
                                                </div>
                                                <div>
                                                    <h4 style={{ fontSize: '16px', fontWeight: '800', color: '#000000' }}>{email}</h4>
                                                    <p style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>{data.responses.length} / {activeExam.questions?.length || '?'} Questions Answered</p>
                                                </div>
                                            </div>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
                                                <div style={{ textAlign: 'right' }}>
                                                    <p style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Current Score</p>
                                                    <p style={{ fontSize: '20px', fontWeight: '900', color: '#6366f1' }}>{data.totalScore.toFixed(1)} <span style={{ fontSize: '14px', color: 'gray' }}>/ {activeExam.questions?.length * 10}</span></p>
                                                </div>
                                                {isExpanded ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
                                            </div>
                                        </button>

                                        {/* Expanded Answer Breakdown */}
                                        <AnimatePresence>
                                            {isExpanded && (
                                                <motion.div
                                                    initial={{ height: 0, opacity: 0 }}
                                                    animate={{ height: 'auto', opacity: 1 }}
                                                    exit={{ height: 0, opacity: 0 }}
                                                    style={{ overflow: 'hidden', background: '#fafafa', borderTop: '2px solid #000000' }}
                                                >
                                                    <div style={{ padding: '24px' }}>
                                                        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                                                            <thead>
                                                                <tr style={{ borderBottom: '2px solid #e5e7eb' }}>
                                                                    <th style={{ padding: '0 16px 16px 0', fontSize: '11px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase', textAlign: 'left', width: '30%' }}>Question (Original Text)</th>
                                                                    <th style={{ padding: '0 16px 16px', fontSize: '11px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase', textAlign: 'left', width: '25%' }}>Student Transcript</th>
                                                                    <th style={{ padding: '0 16px 16px', fontSize: '11px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase', textAlign: 'left', width: '25%' }}>Expected Answer</th>
                                                                    <th style={{ padding: '0 16px 16px', fontSize: '11px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase', textAlign: 'center' }}>Grade</th>
                                                                    <th style={{ padding: '0 0 16px 16px', fontSize: '11px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase', textAlign: 'right' }}>Points</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                                {data.responses.sort((a, b) => a.question_index - b.question_index).map((ans, ix) => {
                                                                    const qData = activeExam.questions?.find(q => q.id === ans.question_id);
                                                                    const qText = qData?.text || `Question ${ans.question_index + 1}`;

                                                                    let expectedStr = qData?.correct_answer || qData?.keywords?.join(", ") || "N/A";

                                                                    return (
                                                                        <tr key={ans.id} style={{ borderBottom: ix < data.responses.length - 1 ? '1px solid #e5e7eb' : 'none' }}>
                                                                            <td style={{ padding: '16px 16px 16px 0', verticalAlign: 'top' }}>
                                                                                <span style={{ fontSize: '11px', fontWeight: '900', color: '#6366f1', display: 'block', marginBottom: '4px' }}>{qData?.type === 'MCQ' ? 'MCQ ' : 'THEORY '}{ans.question_index ? `Q${ans.question_index + 1}` : ''}</span>
                                                                                <p style={{ fontSize: '13px', fontWeight: '600', color: '#374151', lineHeight: '1.4' }}>{qText}</p>
                                                                            </td>
                                                                            <td style={{ padding: '16px', verticalAlign: 'top' }}>
                                                                                <p style={{ fontSize: '14px', fontWeight: '500', color: '#000000', fontStyle: 'italic' }}>"{ans.transcript}"</p>
                                                                            </td>
                                                                            <td style={{ padding: '16px', verticalAlign: 'top' }}>
                                                                                <p style={{ fontSize: '13px', fontWeight: '600', color: '#10b981' }}>{expectedStr}</p>
                                                                            </td>
                                                                            <td style={{ padding: '16px', verticalAlign: 'top', textAlign: 'center' }}>
                                                                                <span style={{
                                                                                    padding: '4px 8px',
                                                                                    fontSize: '10px',
                                                                                    fontWeight: '900',
                                                                                    background: ans.is_correct ? '#10b981' : '#ef4444',
                                                                                    color: '#ffffff',
                                                                                    textTransform: 'uppercase'
                                                                                }}>
                                                                                    {ans.is_correct ? 'Correct' : 'Incorrect'}
                                                                                </span>
                                                                            </td>
                                                                            <td style={{ padding: '16px 0 16px 16px', verticalAlign: 'top', textAlign: 'right', fontWeight: '900', fontSize: '16px', whiteSpace: 'nowrap' }}>
                                                                                {ans.score.toFixed(1)} <span style={{ fontSize: '12px', color: 'gray', fontWeight: 'normal' }}>/ 10</span>
                                                                            </td>
                                                                        </tr>
                                                                    );
                                                                })}
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </motion.div>
                                            )}
                                        </AnimatePresence>
                                    </div>
                                );
                            })
                        )}
                    </div>
                </div>
            )}

            <style>{`
        @keyframes pulse {
          0% { transform: scale(0.95); opacity: 0.7; }
          50% { transform: scale(1.1); opacity: 1; }
          100% { transform: scale(0.95); opacity: 0.7; }
        }
      `}</style>
        </div>
    );
};

export default MonitoringPage;
