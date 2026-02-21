import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Shield, Lock, User, Activity } from 'lucide-react';
import { motion } from 'framer-motion';

const LoginPage = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const { login, error, loading } = useAuth();

    const handleSubmit = async (e) => {
        e.preventDefault();
        await login(email, password);
    };

    return (
        <div className="page-fade-in" style={{
            height: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: '#ffffff',
            position: 'relative',
            overflow: 'hidden',
            padding: '24px'
        }}>
            {/* Architectural Background Elements */}
            <div style={{
                position: 'absolute',
                inset: 0,
                backgroundImage: 'radial-gradient(#000 0.5px, transparent 0.5px)',
                backgroundSize: '24px 24px',
                opacity: 0.05,
                zIndex: 0
            }} />

            <motion.div
                initial={{ opacity: 0, x: -100 }}
                animate={{ opacity: 0.1, x: 0 }}
                style={{
                    position: 'absolute',
                    top: '10%',
                    left: '-5%',
                    fontSize: '20vh',
                    fontWeight: '900',
                    color: '#000',
                    zIndex: 0,
                    whiteSpace: 'nowrap',
                    pointerEvents: 'none'
                }}
            >
                UNI ELEVATE
            </motion.div>

            <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                style={{
                    width: '100%',
                    maxWidth: '480px',
                    padding: '64px',
                    background: '#ffffff',
                    border: '4px solid #000000',
                    boxShadow: '24px 24px 0px #000000',
                    position: 'relative',
                    zIndex: 1
                }}
            >
                {/* Branding Section */}
                <div style={{ textAlign: 'center', marginBottom: '48px' }}>
                    <motion.div
                        animate={{ rotate: [0, 90, 180, 270, 360] }}
                        transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
                        style={{
                            width: '80px',
                            height: '80px',
                            border: '2px solid #000',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            margin: '0 auto 32px',
                            position: 'relative'
                        }}
                    >
                        <Shield color="#00d2ff" size={40} />
                        <div style={{ position: 'absolute', top: '-6px', left: '-6px', width: '12px', height: '12px', background: '#000' }} />
                        <div style={{ position: 'absolute', bottom: '-6px', right: '-6px', width: '12px', height: '12px', background: '#000' }} />
                    </motion.div>

                    <h1 style={{
                        fontSize: '32px',
                        fontWeight: '900',
                        marginBottom: '8px',
                        letterSpacing: '2px',
                        textTransform: 'uppercase',
                        color: '#000'
                    }}>
                        UniElevate <span style={{ color: '#00d2ff' }}>PRO</span>
                    </h1>
                    <p style={{
                        color: 'rgba(0,0,0,0.5)',
                        fontSize: '11px',
                        fontWeight: '800',
                        letterSpacing: '1px',
                        textTransform: 'uppercase'
                    }}>
                        Internal Administrative Terminal
                    </p>
                </div>

                <form onSubmit={handleSubmit}>
                    <div style={{ marginBottom: '24px' }}>
                        <label style={{
                            display: 'block',
                            fontSize: '11px',
                            fontWeight: '900',
                            color: '#000',
                            marginBottom: '12px',
                            letterSpacing: '1px'
                        }}>
                            REGISTRY ACCESS (EMAIL)
                        </label>
                        <div style={{ position: 'relative' }}>
                            <User size={18} style={{ position: 'absolute', left: '16px', top: '16px', color: '#000' }} />
                            <input
                                type="email"
                                className="input-field"
                                placeholder="ADMIN@UNI.EDU"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                style={{
                                    paddingLeft: '52px',
                                    borderWidth: '3px',
                                    fontWeight: '700',
                                    textTransform: 'uppercase'
                                }}
                            />
                        </div>
                    </div>

                    <div style={{ marginBottom: '40px' }}>
                        <label style={{
                            display: 'block',
                            fontSize: '11px',
                            fontWeight: '900',
                            color: '#000',
                            marginBottom: '12px',
                            letterSpacing: '1px'
                        }}>
                            SECURE KEYCODE (PASSWORD)
                        </label>
                        <div style={{ position: 'relative' }}>
                            <Lock size={18} style={{ position: 'absolute', left: '16px', top: '16px', color: '#000' }} />
                            <input
                                type="password"
                                className="input-field"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                style={{
                                    paddingLeft: '52px',
                                    borderWidth: '3px'
                                }}
                            />
                        </div>
                    </div>

                    {error && (
                        <motion.div
                            initial={{ x: -10 }}
                            animate={{ x: 0 }}
                            style={{
                                background: '#000',
                                color: '#ff4444',
                                padding: '12px 16px',
                                fontSize: '11px',
                                fontWeight: '900',
                                marginBottom: '24px',
                                borderLeft: '4px solid #ff4444',
                                textTransform: 'uppercase'
                            }}
                        >
                            ACCESS DENIED: {error}
                        </motion.div>
                    )}

                    <motion.button
                        whileHover={{ x: 4, y: 4, boxShadow: '0px 0px 0px #000' }}
                        whileTap={{ scale: 0.98 }}
                        type="submit"
                        className="btn-primary"
                        style={{
                            width: '100%',
                            borderRadius: '0',
                            background: '#000000',
                            color: '#ffffff',
                            fontWeight: '900',
                            padding: '20px',
                            border: 'none',
                            letterSpacing: '2px',
                            fontSize: '14px',
                            textTransform: 'uppercase',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '12px'
                        }}
                        disabled={loading}
                    >
                        {loading ? 'INITIALIZING...' : (
                            <>
                                INITIALIZE ACCESS <Activity size={18} />
                            </>
                        )}
                    </motion.button>
                </form>

                {/* Status Footer */}
                <div style={{
                    marginTop: '48px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    fontSize: '9px',
                    fontWeight: '900',
                    color: 'rgba(0,0,0,0.3)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px'
                }}>
                    <span>STATUS: OPERATIONAL</span>
                    <span>V: 2.4.0_PRO</span>
                </div>
            </motion.div>

            {/* Corner Decorative Elements */}
            <div style={{ position: 'absolute', top: '40px', right: '40px', width: '40px', height: '40px', borderTop: '4px solid #000', borderRight: '4px solid #000' }} />
            <div style={{ position: 'absolute', bottom: '40px', left: '40px', width: '40px', height: '40px', borderBottom: '4px solid #000', borderLeft: '4px solid #000' }} />
        </div>
    );
};

export default LoginPage;
