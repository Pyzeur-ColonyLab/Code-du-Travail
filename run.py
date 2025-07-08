#!/usr/bin/env python3
"""
Universal runner script for Code du Travail bots with additional features
Supports running Telegram bot, Email bot, or both simultaneously
"""

import sys
import os
import argparse
import threading
import time
import signal
import asyncio
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

def setup_directories():
    """Create necessary directories with proper permissions"""
    # Create logs directory
    logs_dir = Path('logs')
    logs_dir.mkdir(exist_ok=True)
    
    # Create cache directory
    cache_dir = Path('cache')
    cache_dir.mkdir(exist_ok=True)
    
    # Set proper permissions (readable/writable by all)
    logs_dir.chmod(0o755)
    cache_dir.chmod(0o755)
    
    print("✅ Directories created with proper permissions")

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

def run_telegram_bot():
    """Run the Telegram bot with proper asyncio setup"""
    try:
        # Create new event loop for this thread
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        from telegram_bot import main
        loop.run_until_complete(main())
    except Exception as e:
        print(f"❌ Error running Telegram bot: {e}")
        raise
    finally:
        try:
            loop.close()
        except:
            pass

def run_email_bot():
    """Run the Email bot"""
    try:
        from mailserver_email_bot import main as run_email_bot
        run_email_bot()
    except Exception as e:
        print(f"❌ Error running Email bot: {e}")
        raise

def run_both_bots():
    """Run both bots simultaneously"""
    print("🚀 Starting both Telegram and Email bots...")
    
    # Create threads for both bots
    telegram_thread = threading.Thread(target=run_telegram_bot, name="TelegramBot")
    email_thread = threading.Thread(target=run_email_bot, name="EmailBot")
    
    # Set threads as daemon so they stop when main program stops
    telegram_thread.daemon = True
    email_thread.daemon = True
    
    # Start both threads
    telegram_thread.start()
    print("✅ Telegram bot started")
    
    # Wait a bit before starting email bot
    time.sleep(2)
    
    email_thread.start()
    print("✅ Email bot started")
    
    try:
        # Keep main thread alive
        while True:
            if not telegram_thread.is_alive():
                print("⚠️ Telegram bot thread stopped")
                break
            if not email_thread.is_alive():
                print("⚠️ Email bot thread stopped")
                break
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n👋 Stopping both bots...")
    
    # Wait for threads to finish
    telegram_thread.join(timeout=5)
    email_thread.join(timeout=5)

def main():
    parser = argparse.ArgumentParser(description='Code du Travail AI Bots')
    parser.add_argument('--check', action='store_true', help='Check dependencies and configuration')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    parser.add_argument('--mode', choices=['telegram', 'email', 'both'], default='both',
                        help='Bot mode: telegram only, email only, or both (default: both)')
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ['LOG_LEVEL'] = 'DEBUG'
        os.environ['EMAIL_LOG_LEVEL'] = 'DEBUG'
    
    print("🤖 Code du Travail AI Bots")
    print("==========================")
    print(f"Mode: {args.mode}")
    
    # Setup environment
    setup_environment()
    
    # Setup directories
    setup_directories()
    
    # Check dependencies
    check_dependencies()
    
    if args.check:
        print("✅ All checks passed!")
        return
    
    # Setup signal handlers for graceful shutdown
    def signal_handler(signum, frame):
        print(f"\n👋 Received signal {signum}, shutting down...")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        if args.mode == 'telegram':
            print("🚀 Starting Telegram bot only...")
            run_telegram_bot()
        elif args.mode == 'email':
            print("🚀 Starting Email bot only...")
            run_email_bot()
        elif args.mode == 'both':
            run_both_bots()
    except KeyboardInterrupt:
        print("\n👋 Bots stopped by user")
    except Exception as e:
        print(f"❌ Error running bots: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()