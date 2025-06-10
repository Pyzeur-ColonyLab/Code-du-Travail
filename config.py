#!/usr/bin/env python3
"""
Configuration file for the Telegram Bot
"""

import os
from typing import Dict, Any

class Config:
    """Configuration class for the bot"""
    
    # Telegram settings
    TELEGRAM_BOT_TOKEN: str = os.getenv('TELEGRAM_BOT_TOKEN', '')
    
    # Model settings
    MODEL_NAME: str = os.getenv('MODEL_NAME', 'Pyzeur/Code-du-Travail-mistral-finetune')
    DEVICE: str = os.getenv('DEVICE', 'auto')
    MAX_LENGTH: int = int(os.getenv('MAX_LENGTH', '2048'))
    
    # Generation parameters
    GENERATION_CONFIG: Dict[str, Any] = {
        'max_new_tokens': 512,
        'do_sample': True,
        'temperature': 0.7,
        'top_p': 0.9,
        'top_k': 50,
        'repetition_penalty': 1.1
    }
    
    # Quantization settings
    USE_QUANTIZATION: bool = os.getenv('USE_QUANTIZATION', 'true').lower() == 'true'
    LOAD_IN_4BIT: bool = os.getenv('LOAD_IN_4BIT', 'true').lower() == 'true'
    
    # Logging
    LOG_LEVEL: str = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE: str = os.getenv('LOG_FILE', 'bot.log')
    
    @classmethod
    def validate(cls) -> bool:
        """Validate required configuration"""
        if not cls.TELEGRAM_BOT_TOKEN:
            raise ValueError("TELEGRAM_BOT_TOKEN is required")
        return True