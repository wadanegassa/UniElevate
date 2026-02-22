import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertCircle } from 'lucide-react';

const ConfirmModal = ({ isOpen, onClose, onConfirm, title, message, type = 'danger' }) => {
    const accentColor = type === 'danger' ? '#ef4444' : '#6366f1';

    return (
        <AnimatePresence mode="wait">
            {isOpen && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0, 0, 0, 0.4)',
                    backdropFilter: 'blur(8px)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1000,
                    padding: '20px'
                }}>
                    <motion.div
                        initial={{ scale: 0.9, opacity: 0, y: 20 }}
                        animate={{ scale: 1, opacity: 1, y: 0 }}
                        exit={{ scale: 0.9, opacity: 0, y: 20 }}
                        transition={{ duration: 0.2 }}
                        style={{
                            background: '#ffffff',
                            width: '100%',
                            maxWidth: '450px',
                            borderRadius: '0',
                            boxShadow: `24px 24px 0px #000000`,
                            border: '4px solid #000000',
                            position: 'relative',
                            overflow: 'hidden'
                        }}
                    >
                        {/* Header bar */}
                        <div style={{ height: '8px', background: accentColor }} />

                        <div style={{ padding: '32px' }}>
                            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '20px', marginBottom: '24px' }}>
                                <div style={{
                                    width: '48px',
                                    height: '48px',
                                    background: `${accentColor}15`,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    borderRadius: '12px',
                                    flexShrink: 0
                                }}>
                                    <AlertCircle color={accentColor} size={24} style={{ margin: 'auto' }} />
                                </div>
                                <div>
                                    <h3 style={{ fontSize: '20px', fontWeight: '900', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                        {title}
                                    </h3>
                                    <p style={{ color: 'var(--text-secondary)', lineHeight: '1.6', fontSize: '15px' }}>
                                        {message}
                                    </p>
                                </div>
                            </div>

                            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                                <button
                                    onClick={onClose}
                                    style={{
                                        padding: '12px 24px',
                                        background: 'transparent',
                                        border: '2px solid #e5e7eb',
                                        fontWeight: '800',
                                        cursor: 'pointer',
                                        fontSize: '13px'
                                    }}
                                >
                                    CANCEL
                                </button>
                                <button
                                    onClick={() => {
                                        onConfirm();
                                        onClose();
                                    }}
                                    style={{
                                        padding: '12px 24px',
                                        background: accentColor,
                                        color: '#ffffff',
                                        border: 'none',
                                        fontWeight: '900',
                                        cursor: 'pointer',
                                        fontSize: '13px',
                                        boxShadow: `4px 4px 0px #000000`
                                    }}
                                >
                                    {type === 'danger' ? 'DELETE FOREVER' : 'PROCEED'}
                                </button>
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};

export default ConfirmModal;
