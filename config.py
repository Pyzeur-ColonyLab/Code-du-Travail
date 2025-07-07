#!/usr/bin/env python3
"""
Configuration file for Code du Travail AI Bots (Telegram and Email)
"""

import os
from typing import Dict, Any

class Config:
    """Configuration class for both Telegram and Email bots"""
    
    # Telegram settings
    TELEGRAM_BOT_TOKEN: str = os.getenv('TELEGRAM_BOT_TOKEN', '')
    
    # Email settings (Docker-Mailserver)
    EMAIL_ADDRESS: str = os.getenv('EMAIL_ADDRESS', '')
    EMAIL_PASSWORD: str = os.getenv('EMAIL_PASSWORD', '')
    EMAIL_DOMAIN: str = os.getenv('EMAIL_DOMAIN', '')
    
    # Email server settings
    IMAP_HOST: str = os.getenv('IMAP_HOST', 'localhost')
    IMAP_PORT: int = int(os.getenv('IMAP_PORT', '993'))
    SMTP_HOST: str = os.getenv('SMTP_HOST', 'localhost')
    SMTP_PORT: int = int(os.getenv('SMTP_PORT', '587'))
    
    # Model settings
    MODEL_NAME: str = os.getenv('MODEL_NAME', 'Pyzeur/Code-du-Travail-mistral-finetune')
    DEVICE: str = os.getenv('DEVICE', 'auto')
    MAX_LENGTH: int = int(os.getenv('MAX_LENGTH', '2048'))
    HUGGING_FACE_TOKEN: str = os.getenv('HUGGING_FACE_TOKEN', '')
    
    # Telegram generation parameters
    TELEGRAM_GENERATION_CONFIG: Dict[str, Any] = {
        'max_new_tokens': 512,
        'do_sample': True,
        'temperature': 0.7,
        'top_p': 0.9,
        'top_k': 50,
        'repetition_penalty': 1.1
    }
    
    # Email generation parameters (optimized for longer, more detailed responses)
    EMAIL_GENERATION_CONFIG: Dict[str, Any] = {
        'max_new_tokens': int(os.getenv('EMAIL_MAX_TOKENS', '1500')),
        'do_sample': True,
        'temperature': float(os.getenv('EMAIL_TEMPERATURE', '0.3')),
        'top_p': float(os.getenv('EMAIL_TOP_P', '0.95')),
        'top_k': int(os.getenv('EMAIL_TOP_K', '50')),
        'repetition_penalty': float(os.getenv('EMAIL_REPETITION_PENALTY', '1.15'))
    }
    
    # Email bot settings
    EMAIL_CHECK_INTERVAL: int = int(os.getenv('EMAIL_CHECK_INTERVAL', '30'))
    EMAIL_SIGNATURE: str = os.getenv('EMAIL_SIGNATURE', 'Assistant IA Code du Travail - ColonyLab')
    EMAIL_DISCLAIMER: str = os.getenv('EMAIL_DISCLAIMER', 
        'Cette réponse est fournie à titre informatif uniquement. '
        'Pour des conseils juridiques précis et personnalisés, '
        'consultez un avocat spécialisé en droit du travail.')
    
    # Quantization settings
    USE_QUANTIZATION: bool = os.getenv('USE_QUANTIZATION', 'true').lower() == 'true'
    LOAD_IN_4BIT: bool = os.getenv('LOAD_IN_4BIT', 'true').lower() == 'true'
    
    # Logging
    LOG_LEVEL: str = os.getenv('LOG_LEVEL', 'INFO')
    EMAIL_LOG_LEVEL: str = os.getenv('EMAIL_LOG_LEVEL', 'INFO')
    LOG_FILE: str = os.getenv('LOG_FILE', 'bot.log')
    
    @classmethod
    def validate_telegram(cls) -> bool:
        """Validate Telegram configuration"""
        if not cls.TELEGRAM_BOT_TOKEN:
            raise ValueError("TELEGRAM_BOT_TOKEN is required for Telegram bot")
        return True
    
    @classmethod
    def validate_email(cls) -> bool:
        """Validate Email configuration"""
        if not cls.EMAIL_ADDRESS:
            raise ValueError("EMAIL_ADDRESS is required for Email bot")
        if not cls.EMAIL_PASSWORD:
            raise ValueError("EMAIL_PASSWORD is required for Email bot")
        if not cls.EMAIL_DOMAIN:
            raise ValueError("EMAIL_DOMAIN is required for Email bot")
        return True
    
    @classmethod
    def validate_all(cls) -> bool:
        """Validate all configuration"""
        cls.validate_telegram()
        cls.validate_email()
        return True