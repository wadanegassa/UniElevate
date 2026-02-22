import React, { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { format } from 'date-fns';
import { Wifi, Activity, Terminal } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const MonitoringPage = () => {
    const [answers, setAnswers] = useState([]);
    const [exams, setExams] = useState([]);
    const [loading, setLoading] = useState(true);

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
            .select('*')
            .order('created_at', { ascending: false })
            .limit(5);
        if (data) setExams(data);
        setLoading(false);
    };

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

            <section style={{ marginBottom: '40px' }}>
                <h2 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Wifi size={18} color="var(--accent-indigo)" /> Recently Deployed Exams
                </h2>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
                    {exams.map(ex => (
                        <div key={ex.id} style={{
                            padding: '24px',
                            border: '2px solid #000000',
                            background: '#ffffff',
                            boxShadow: '8px 8px 0px #000000'
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
                                <span style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                                    {ex.created_at ? format(new Date(ex.created_at), 'MMM d, HH:mm') : '---'}
                                </span>
                                <div style={{ background: '#000000', color: '#ffffff', padding: '4px 8px', borderRadius: '0', fontSize: '11px', fontWeight: '900' }}>
                                    {ex.access_code}
                                </div>
                            </div>
                            <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '4px', textTransform: 'uppercase' }}>{ex.title}</h3>
                            <p style={{ fontSize: '12px', color: 'var(--text-secondary)', fontWeight: '600' }}>{ex.duration} Minutes • ACTIVE</p>
                        </div>
                    ))}
                    {exams.length === 0 && (
                        <div className="glass-panel" style={{ padding: '32px', textAlign: 'center', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>
                            No exams deployed yet.
                        </div>
                    )}
                </div>
            </section>

            <div style={{ border: '2px solid #000000', background: '#ffffff' }}>
                <div style={{ padding: '24px', borderBottom: '2px solid #000000', display: 'flex', alignItems: 'center', gap: '12px', background: '#f8f8f8' }}>
                    <Terminal size={18} color="#000000" />
                    <span style={{ fontSize: '14px', fontWeight: '900', color: '#000000', textTransform: 'uppercase', letterSpacing: '1px' }}>Activity Stream</span>
                </div>

                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                        <thead>
                            <tr style={{ borderBottom: '2px solid #000000', background: '#ffffff' }}>
                                <th style={{ padding: '16px 24px', fontSize: '11px', color: '#000000', fontWeight: '900', textTransform: 'uppercase' }}>TIMESTAMP</th>
                                <th style={{ padding: '16px 24px', fontSize: '11px', color: '#000000', fontWeight: '900', textTransform: 'uppercase' }}>STUDENT</th>
                                <th style={{ padding: '16px 24px', fontSize: '11px', color: '#000000', fontWeight: '900', textTransform: 'uppercase' }}>TRANSCRIPT</th>
                                <th style={{ padding: '16px 24px', fontSize: '11px', color: '#000000', fontWeight: '900', textTransform: 'uppercase' }}>GRADE</th>
                                <th style={{ padding: '16px 24px', fontSize: '11px', color: '#000000', fontWeight: '900', textTransform: 'uppercase' }}>SCORE</th>
                            </tr>
                        </thead>
                        <tbody>
                            <AnimatePresence initial={false}>
                                {answers.map((answer, ix) => (
                                    <motion.tr
                                        key={answer.timestamp + ix}
                                        initial={{ opacity: 0, x: -10, background: '#f5f3ff' }}
                                        animate={{ opacity: 1, x: 0, background: '#ffffff' }}
                                        style={{ borderBottom: '2px solid #000000', transition: 'background 0.2s ease' }}
                                    >
                                        <td style={{ padding: '20px 24px', fontSize: '13px', color: '#000000', fontWeight: '800' }}>
                                            {format(new Date(answer.timestamp), 'HH:mm:ss')}
                                        </td>
                                        <td style={{ padding: '20px 24px', fontSize: '14px', fontWeight: '800', color: '#6366f1' }}>
                                            {answer.profiles?.email || answer.student_id?.substring(0, 8) || 'ANONYMOUS'}
                                        </td>
                                        <td style={{ padding: '20px 24px', fontSize: '14px', maxWidth: '400px' }}>
                                            <p style={{ fontWeight: '500', color: '#000000' }}>
                                                "{answer.transcript}"
                                            </p>
                                        </td>
                                        <td style={{ padding: '20px 24px' }}>
                                            <span style={{
                                                padding: '6px 14px',
                                                borderRadius: '0',
                                                fontSize: '11px',
                                                fontWeight: '950',
                                                background: answer.is_correct ? '#6366f1' : '#000000',
                                                color: '#ffffff',
                                                border: `none`,
                                                textTransform: 'uppercase',
                                                letterSpacing: '1px'
                                            }}>
                                                {answer.is_correct ? 'GRADED: OK' : 'GRADED: ERR'}
                                            </span>
                                        </td>
                                        <td style={{ padding: '20px 24px', fontWeight: '950', fontSize: '18px', color: '#000000' }}>
                                            {answer.score.toFixed(1)}
                                        </td>
                                    </motion.tr>
                                ))}
                            </AnimatePresence>

                            {!loading && answers.length === 0 && (
                                <tr>
                                    <td colSpan="5" style={{ padding: '80px 0', textAlign: 'center', color: 'var(--text-muted)' }}>
                                        <Activity size={48} style={{ opacity: 0.1, marginBottom: '16px' }} />
                                        <p>Waiting for live student responses...</p>
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

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
