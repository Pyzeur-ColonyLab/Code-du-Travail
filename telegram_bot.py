#!/usr/bin/env python3
"""
Telegram Bot for Code du Travail - Mistral 7B Fine-tuned Model

This bot integrates a fine-tuned Mistral 7B model with Telegram to answer
questions about French labor law (Code du Travail).
"""

import os
import logging
import asyncio
from typing import Optional
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from dotenv import load_dotenv
import psutil
import time

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    handlers=[
        logging.FileHandler('bot.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class MistralTelegramBot:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = "Pyzeur/Code-du-Travail-mistral-finetune"
        self.max_length = 2048
        self.is_loading = False
        
        # Get environment variables
        self.telegram_token = os.getenv('TELEGRAM_BOT_TOKEN')
        if not self.telegram_token:
            raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
            
        logger.info(f"Initializing bot with device: {self.device}")
        
    async def load_model(self):
        """Load the fine-tuned model and tokenizer"""
        if self.model is not None:
            return
            
        self.is_loading = True
        logger.info("Loading model and tokenizer...")
        
        try:
            # Get authentication token if available
            use_auth_token = os.getenv('HUGGING_FACE_TOKEN')
            if use_auth_token:
                logger.info("Using HuggingFace authentication token")
            
            # Configure quantization for memory efficiency on GPU
            if self.device == "cuda":
                quantization_config = BitsAndBytesConfig(
                    load_in_4bit=True,
                    bnb_4bit_compute_dtype=torch.float16,
                    bnb_4bit_use_double_quant=True,
                    bnb_4bit_quant_type="nf4"
                )
            else:
                quantization_config = None
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.model_name,
                trust_remote_code=True,
                use_auth_token=use_auth_token
            )
            
            # Add pad token if it doesn't exist
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
            
            # Load model
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_name,
                quantization_config=quantization_config,
                device_map="auto" if self.device == "cuda" else None,
                torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
                trust_remote_code=True,
                use_auth_token=use_auth_token
            )
            
            if self.device == "cpu":
                self.model = self.model.to(self.device)
            
            logger.info("Model loaded successfully!")
            
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            raise
        finally:
            self.is_loading = False
    
    def generate_response(self, question: str) -> str:
        """Generate response using the fine-tuned model"""
        if self.model is None or self.tokenizer is None:
            return "❌ Le modèle n'est pas encore chargé. Veuillez patienter..."
        
        try:
            # Format the prompt (adjust based on your fine-tuning format)
            prompt = f"Question: {question}\nRéponse:"
            
            # Tokenize input
            inputs = self.tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=self.max_length // 2
            ).to(self.device)
            
            # Generate response
            with torch.no_grad():
                outputs = self.model.generate(
                    **inputs,
                    max_new_tokens=512,
                    do_sample=True,
                    temperature=0.7,
                    top_p=0.9,
                    top_k=50,
                    repetition_penalty=1.1,
                    pad_token_id=self.tokenizer.eos_token_id,
                    eos_token_id=self.tokenizer.eos_token_id
                )
            
            # Decode response
            response = self.tokenizer.decode(
                outputs[0][inputs.input_ids.shape[1]:],
                skip_special_tokens=True
            ).strip()
            
            # Clean up response
            if not response:
                response = "Je n'ai pas pu générer une réponse appropriée à votre question."
            
            return response
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return f"❌ Erreur lors de la génération de la réponse: {str(e)}"
    
    def get_system_info(self) -> str:
        """Get system information"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            info = f"📊 **Informations système:**\n\n"
            info += f"🖥️ CPU: {cpu_percent}%\n"
            info += f"💾 RAM: {memory.percent}% ({memory.used // (1024**3)}GB / {memory.total // (1024**3)}GB)\n"
            info += f"💿 Disque: {disk.percent}% ({disk.used // (1024**3)}GB / {disk.total // (1024**3)}GB)\n"
            info += f"🔧 Device: {self.device.upper()}\n"
            
            if torch.cuda.is_available():
                gpu_memory = torch.cuda.get_device_properties(0).total_memory // (1024**3)
                gpu_used = torch.cuda.memory_allocated(0) // (1024**3)
                info += f"🎮 GPU: {gpu_used}GB / {gpu_memory}GB\n"
            
            info += f"🤖 Modèle: {'Chargé' if self.model else 'Non chargé'}\n"
            
            return info
            
        except Exception as e:
            return f"❌ Erreur lors de la récupération des informations système: {str(e)}"

# Initialize bot instance
bot_instance = MistralTelegramBot()

# Command handlers
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /start is issued."""
    welcome_message = (
        "👋 Bonjour ! Je suis votre assistant virtuel spécialisé dans le Code du Travail français.\n\n"
        "💼 Posez-moi vos questions sur le droit du travail, les congés, les contrats, "
        "les procédures de licenciement, et bien plus encore !\n\n"
        "📝 **Commandes disponibles:**\n"
        "/start - Afficher ce message\n"
        "/help - Aide et informations\n"
        "/status - État du système\n\n"
        "✨ Envoyez-moi simplement votre question et je vous répondrai !"
    )
    
    await update.message.reply_text(welcome_message, parse_mode='Markdown')
    
    # Load model if not already loaded
    if bot_instance.model is None and not bot_instance.is_loading:
        await update.message.reply_text("🔄 Chargement du modèle en cours, veuillez patienter...")
        await bot_instance.load_model()
        await update.message.reply_text("✅ Modèle chargé ! Vous pouvez maintenant poser vos questions.")

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /help is issued."""
    help_text = (
        "🆘 **Aide - Bot Code du Travail**\n\n"
        "Ce bot utilise un modèle Mistral 7B fine-tuné spécialement pour répondre "
        "aux questions sur le Code du Travail français.\n\n"
        "📋 **Comment utiliser le bot:**\n"
        "• Posez vos questions directement\n"
        "• Soyez précis dans vos demandes\n"
        "• Le bot peut traiter des sujets comme:\n"
        "  - Contrats de travail\n"
        "  - Congés et RTT\n"
        "  - Licenciements\n"
        "  - Temps de travail\n"
        "  - Salaires et primes\n"
        "  - Relations sociales\n\n"
        "⚠️ **Avertissement:** Les réponses sont fournies à titre informatif. "
        "Pour des conseils juridiques précis, consultez un avocat spécialisé."
    )
    
    await update.message.reply_text(help_text, parse_mode='Markdown')

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Show system status"""
    status_info = bot_instance.get_system_info()
    await update.message.reply_text(status_info, parse_mode='Markdown')

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle incoming messages and generate responses"""
    user_message = update.message.text
    user_id = update.effective_user.id
    username = update.effective_user.username or "Unknown"
    
    logger.info(f"Received message from {username} ({user_id}): {user_message[:100]}...")
    
    # Check if model is loading
    if bot_instance.is_loading:
        await update.message.reply_text(
            "🔄 Le modèle est en cours de chargement, veuillez patienter quelques instants..."
        )
        return
    
    # Load model if not loaded
    if bot_instance.model is None:
        await update.message.reply_text("🔄 Chargement du modèle...")
        try:
            await bot_instance.load_model()
            await update.message.reply_text("✅ Modèle chargé !")
        except Exception as e:
            await update.message.reply_text(f"❌ Erreur lors du chargement du modèle: {str(e)}")
            return
    
    # Show typing indicator
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action="typing")
    
    # Generate response
    start_time = time.time()
    response = bot_instance.generate_response(user_message)
    end_time = time.time()
    
    logger.info(f"Generated response in {end_time - start_time:.2f}s for user {username}")
    
    # Send response
    try:
        await update.message.reply_text(response)
    except Exception as e:
        logger.error(f"Error sending response: {e}")
        await update.message.reply_text(
            "❌ Désolé, une erreur s'est produite lors de l'envoi de la réponse."
        )

async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Log errors caused by Updates."""
    logger.error(f"Update {update} caused error {context.error}")

def main() -> None:
    """Start the bot."""
    # Create the Application
    application = Application.builder().token(bot_instance.telegram_token).build()
    
    # Register handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("status", status))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # Register error handler
    application.add_error_handler(error_handler)
    
    # Start the bot
    logger.info("Starting Telegram bot...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == '__main__':
    main()
