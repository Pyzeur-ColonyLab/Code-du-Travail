#!/usr/bin/env python3
"""
Email Bot for Code du Travail - Mistral 7B Fine-tuned Model

This bot monitors Gmail for incoming questions and responds automatically
using the fine-tuned Mistral 7B model for French labor law questions.
"""

import os
import logging
import time
import email
import imaplib
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import decode_header
from datetime import datetime
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
from dotenv import load_dotenv
import threading
import re

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    handlers=[
        logging.FileHandler('email_bot.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class EmailBot:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = "Pyzeur/Code-du-Travail-mistral-finetune"
        self.base_model_name = "mistralai/Mistral-7B-Instruct-v0.3"
        self.is_loading = False
        self.processed_emails = set()  # Track processed emails
        
        # Email configuration
        self.email_address = os.getenv('EMAIL_ADDRESS')
        self.email_password = os.getenv('EMAIL_PASSWORD')
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.imap_server = "imap.gmail.com"
        self.imap_port = 993
        
        # Validate email configuration
        if not self.email_address or not self.email_password:
            raise ValueError("EMAIL_ADDRESS and EMAIL_PASSWORD must be set in .env")
        
        logger.info(f"Email bot initialized for: {self.email_address}")
        logger.info(f"Device: {self.device}")
        
    def load_model(self):
        """Load the fine-tuned LoRA model"""
        if self.model is not None:
            return
            
        self.is_loading = True
        logger.info("Loading LoRA model for email responses...")
        
        try:
            # Get HuggingFace token
            use_auth_token = os.getenv('HUGGING_FACE_TOKEN')
            if use_auth_token:
                logger.info("Using HuggingFace authentication token")
            
            # Load tokenizer
            logger.info(f"Loading tokenizer from {self.base_model_name}...")
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.base_model_name,
                trust_remote_code=True,
                token=use_auth_token
            )
            
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
            
            # Load base model
            logger.info(f"Loading base model {self.base_model_name}...")
            base_model = AutoModelForCausalLM.from_pretrained(
                self.base_model_name,
                torch_dtype=torch.float32,
                trust_remote_code=True,
                token=use_auth_token,
                low_cpu_mem_usage=True,
                use_cache=True
            )
            
            base_model = base_model.to(self.device)
            base_model.eval()
            
            # Load LoRA adapter
            logger.info(f"Loading LoRA adapter from {self.model_name}...")
            self.model = PeftModel.from_pretrained(
                base_model,
                self.model_name,
                token=use_auth_token
            )
            
            self.model.eval()
            logger.info("LoRA model loaded successfully!")
            
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            raise
        finally:
            self.is_loading = False
    
    def generate_response(self, question: str) -> str:
        """Generate response with email-optimized parameters"""
        if self.model is None or self.tokenizer is None:
            return "❌ Le modèle n'est pas encore chargé."
        
        try:
            # Format prompt for Mistral
            prompt = f"<s>[INST] {question} [/INST]"
            
            # Tokenize input
            inputs = self.tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=2048,
                padding=False
            ).to(self.device)
            
            # Email-optimized generation parameters
            generation_config = {
                "max_new_tokens": 1000,  # Longer responses for email
                "do_sample": True,
                "temperature": 0.7,
                "top_p": 0.95,          # More creative
                "top_k": 75,            # More diversity
                "repetition_penalty": 1.1,
                "pad_token_id": self.tokenizer.eos_token_id,
                "eos_token_id": self.tokenizer.eos_token_id,
                "use_cache": True
            }
            
            # Generate response
            with torch.inference_mode():
                outputs = self.model.generate(
                    **inputs,
                    **generation_config
                )
            
            # Decode response
            response = self.tokenizer.decode(
                outputs[0][inputs.input_ids.shape[1]:],
                skip_special_tokens=True
            ).strip()
            
            if not response:
                response = "Je n'ai pas pu générer une réponse appropriée à votre question."
            
            return response
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return f"Erreur lors de la génération de la réponse: {str(e)}"
    
    def format_email_response(self, question: str, ai_response: str) -> str:
        """Format the response with introduction for email"""
        introduction = (
            "Bonjour,\n\n"
            "Merci pour votre question concernant le Code du Travail français. "
            "Voici ma réponse basée sur ma connaissance du droit du travail :"
        )
        
        footer = (
            "\n\n---\n"
            "⚠️ Cette réponse est fournie à titre informatif uniquement. "
            "Pour des conseils juridiques précis et personnalisés, "
            "je vous recommande de consulter un avocat spécialisé en droit du travail.\n\n"
            "Cordialement,\n"
            "Assistant IA Code du Travail"
        )
        
        return f"{introduction}\n\n{ai_response}{footer}"
    
    def send_email(self, to_email: str, subject: str, body: str):
        """Send email response"""
        try:
            msg = MIMEMultipart()
            msg['From'] = self.email_address
            msg['To'] = to_email
            msg['Subject'] = subject
            
            msg.attach(MIMEText(body, 'plain', 'utf-8'))
            
            # Connect to SMTP server
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.email_address, self.email_password)
            
            # Send email
            text = msg.as_string()
            server.sendmail(self.email_address, to_email, text)
            server.quit()
            
            logger.info(f"Email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False
    
    def start(self):
        """Start the email bot"""
        logger.info("Starting Email Bot for Code du Travail...")
        
        # Load model
        logger.info("Loading AI model...")
        self.load_model()
        
        logger.info("Email bot ready!")

def main():
    try:
        bot = EmailBot()
        bot.start()
    except KeyboardInterrupt:
        logger.info("Email bot stopped by user")
    except Exception as e:
        logger.error(f"Email bot error: {e}")

if __name__ == '__main__':
    main()
