#!/usr/bin/env python3
"""
Alternative runner script for the Telegram bot with additional features
"""

import sys
import os
import argparse
from pathlib import Path

# Add current directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

def setup_environment():
    """Setup environment and validate configuration"""
    # Load .env file if it exists
    env_file = Path('.env')
    if env_file.exists():
        try:
            from dotenv import load_dotenv
            load_dotenv()
            print("✅ Loaded .env file")
        except ImportError:
            print("⚠️ python-dotenv not installed, loading .env manually")
            with open('.env') as f:
                for line in f:
                    if line.strip() and not line.startswith('#') and '=' in line:
                        key, value = line.strip().split('=', 1)
                        os.environ[key] = value
    else:
        print("⚠️ No .env file found. Make sure to set environment variables.")
    
    # Check token
    token = os.getenv('TELEGRAM_BOT_TOKEN')
    if not token:
        print("❌ Configuration error: TELEGRAM_BOT_TOKEN is required")
        sys.exit(1)
    else:
        print("✅ Configuration validated")

def check_dependencies():
    """Check if required dependencies are installed"""
    try:
        import torch
        import transformers
        import telegram
        print(f"✅ PyTorch: {torch.__version__}")
        print(f"✅ Transformers: {transformers.__version__}")
        print(f"✅ Python-telegram-bot: {telegram.__version__}")
        
        if torch.cuda.is_available():
            print(f"✅ CUDA available: {torch.cuda.get_device_name(0)}")
        else:
            print("⚠️ CUDA not available, using CPU")
            
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Please install requirements: pip install -r requirements.txt")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Code du Travail Telegram Bot')
    parser.add_argument('--check', action='store_true', help='Check dependencies and configuration')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ['LOG_LEVEL'] = 'DEBUG'
    
    print("🤖 Code du Travail Telegram Bot")
    print("==============================")
    
    # Setup environment
    setup_environment()
    
    # Check dependencies
    check_dependencies()
    
    if args.check:
        print("✅ All checks passed!")
        return
    
    print("🚀 Starting bot...")
    
    try:
        # Import and run the bot
        from telegram_bot import main as run_bot
        run_bot()
    except KeyboardInterrupt:
        print("\n👋 Bot stopped by user")
    except Exception as e:
        print(f"❌ Error running bot: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()