#!/usr/bin/env python3
"""
Docker-Mailserver Email Bot for Code du Travail - Mistral 7B Fine-tuned Model

This bot monitors docker-mailserver for incoming questions and responds automatically
using the fine-tuned Mistral 7B model for French labor law questions.

Optimized for complete and precise responses with the SLM fine-tuned model.
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
import hashlib
import ssl

# Load environment variables
load_dotenv()

# Configure logging
try:
    # Ensure logs directory exists
    os.makedirs('logs', exist_ok=True)
    
    logging.basicConfig(
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        level=getattr(logging, os.getenv('EMAIL_LOG_LEVEL', 'INFO')),
        handlers=[
            logging.FileHandler('logs/mailserver_email_bot.log'),
            logging.StreamHandler()
        ]
    )
except Exception as e:
    # Fallback to console-only logging if file logging fails
    logging.basicConfig(
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        level=getattr(logging, os.getenv('EMAIL_LOG_LEVEL', 'INFO')),
        handlers=[logging.StreamHandler()]
    )
    print(f"⚠️ Could not setup file logging: {e}")
logger = logging.getLogger(__name__)

class MailserverEmailBot:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = self._get_device()
        self.model_name = os.getenv('MODEL_NAME', "Pyzeur/Code-du-Travail-mistral-finetune")
        self.base_model_name = "mistralai/Mistral-7B-Instruct-v0.3"
        self.is_loading = False
        self.processed_emails = set()  # Track processed emails by hash
        self.is_running = False
        
        # Docker-Mailserver configuration
        self.email_address = os.getenv('EMAIL_ADDRESS')
        self.email_password = os.getenv('EMAIL_PASSWORD')
        self.email_domain = os.getenv('EMAIL_DOMAIN')
        self.imap_host = os.getenv('IMAP_HOST', 'localhost')
        self.imap_port = int(os.getenv('IMAP_PORT', '993'))
        self.smtp_host = os.getenv('SMTP_HOST', 'localhost')
        self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
        
        # AI Parameters optimized for fine-tuned model
        self.max_tokens = int(os.getenv('EMAIL_MAX_TOKENS', '1500'))
        self.temperature = float(os.getenv('EMAIL_TEMPERATURE', '0.3'))
        self.top_p = float(os.getenv('EMAIL_TOP_P', '0.95'))
        self.top_k = int(os.getenv('EMAIL_TOP_K', '50'))
        self.repetition_penalty = float(os.getenv('EMAIL_REPETITION_PENALTY', '1.15'))
        
        # Email formatting
        self.signature = os.getenv('EMAIL_SIGNATURE', 'Assistant IA Code du Travail - ColonyLab')
        self.disclaimer = os.getenv('EMAIL_DISCLAIMER', 
            'Cette réponse est fournie à titre informatif uniquement. '
            'Pour des conseils juridiques précis et personnalisés, '
            'consultez un avocat spécialisé en droit du travail.')
        
        # Check interval for new emails
        self.check_interval = int(os.getenv('EMAIL_CHECK_INTERVAL', '30'))
        
        # Validate configuration
        if not self.email_address or not self.email_password:
            raise ValueError("EMAIL_ADDRESS and EMAIL_PASSWORD must be set in .env")
        
        if not self.email_domain:
            raise ValueError("EMAIL_DOMAIN must be set in .env")
        
        logger.info(f"Mailserver email bot initialized for: {self.email_address}")
        logger.info(f"Domain: {self.email_domain}")
        logger.info(f"Device: {self.device}")
        logger.info(f"IMAP: {self.imap_host}:{self.imap_port}")
        logger.info(f"SMTP: {self.smtp_host}:{self.smtp_port}")
        logger.info(f"AI Parameters: tokens={self.max_tokens}, temp={self.temperature}, top_p={self.top_p}")
        
    def _get_device(self):
        """Determine the best device for model inference"""
        device_setting = os.getenv('DEVICE', 'auto').lower()
        
        if device_setting == 'auto':
            if torch.cuda.is_available():
                device = 'cuda'
                logger.info(f"CUDA available: {torch.cuda.get_device_name(0)}")
            else:
                device = 'cpu'
                logger.info("CUDA not available, using CPU")
        else:
            device = device_setting
            
        return device
        
    def load_model(self):
        """Load the fine-tuned LoRA model"""
        if self.model is not None:
            return
            
        self.is_loading = True
        logger.info("Loading fine-tuned LoRA model for precise email responses...")
        
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
            logger.info("Fine-tuned LoRA model loaded successfully!")
            
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            raise
        finally:
            self.is_loading = False
    
    def generate_response(self, question: str) -> str:
        """Generate response using the fine-tuned model with optimized parameters"""
        if self.model is None or self.tokenizer is None:
            return "❌ Le modèle n'est pas encore chargé."
        
        try:
            # Clean and prepare the question
            question = question.strip()
            
            # Format prompt for the fine-tuned Mistral model
            prompt = f"""<s>[INST] Vous êtes un expert juridique spécialisé dans le Code du Travail français. 
Répondez de manière complète, précise et détaillée à la question suivante. 
Structurez votre réponse avec des sections claires et citez les articles pertinents du Code du Travail si applicable.

Question: {question} [/INST]"""
            
            # Tokenize input
            inputs = self.tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=2048,
                padding=False
            ).to(self.device)
            
            # Optimized generation parameters for the fine-tuned model
            generation_config = {
                "max_new_tokens": self.max_tokens,
                "do_sample": True,
                "temperature": self.temperature,
                "top_p": self.top_p,
                "top_k": self.top_k,
                "repetition_penalty": self.repetition_penalty,
                "pad_token_id": self.tokenizer.eos_token_id,
                "eos_token_id": self.tokenizer.eos_token_id,
                "use_cache": True,
                "no_repeat_ngram_size": 3,
                "early_stopping": True
            }
            
            logger.debug(f"Generating response with parameters: {generation_config}")
            
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
                response = "Je n'ai pas pu générer une réponse appropriée à votre question. Pourriez-vous la reformuler ?"
            
            # Clean up the response
            response = self._clean_response(response)
            
            return response
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return f"Erreur lors de la génération de la réponse: {str(e)}"
    
    def _clean_response(self, response: str) -> str:
        """Clean and format the AI response"""
        # Remove common artifacts
        response = re.sub(r'\[INST\].*?\[/INST\]', '', response, flags=re.DOTALL)
        response = re.sub(r'<s>', '', response)
        response = re.sub(r'</s>', '', response)
        
        # Remove excessive whitespace
        response = re.sub(r'\n\s*\n\s*\n', '\n\n', response)
        response = response.strip()
        
        return response
    
    def format_email_response(self, question: str, ai_response: str, sender_email: str) -> str:
        """Format the response for email with proper structure"""
        # Create a personalized greeting
        greeting = f"Bonjour,\n\n"
        
        # Introduction
        introduction = (
            "Merci pour votre question concernant le Code du Travail français. "
            "Voici ma réponse basée sur ma connaissance spécialisée du droit du travail :\n\n"
        )
        
        # Add separator for the main response
        separator = "📋 **Réponse détaillée :**\n\n"
        
        # Footer with disclaimer
        footer = (
            f"\n\n---\n\n"
            f"⚠️ **Avertissement :** {self.disclaimer}\n\n"
            f"Cordialement,\n"
            f"{self.signature}"
        )
        
        return f"{greeting}{introduction}{separator}{ai_response}{footer}"
    
    def connect_imap(self):
        """Connect to IMAP server"""
        try:
            # Create SSL context
            context = ssl.create_default_context()
            
            # Connect to IMAP server
            if self.imap_port == 993:
                # SSL connection
                mail = imaplib.IMAP4_SSL(self.imap_host, self.imap_port, ssl_context=context)
            else:
                # STARTTLS connection
                mail = imaplib.IMAP4(self.imap_host, self.imap_port)
                mail.starttls(ssl_context=context)
            
            # Login
            mail.login(self.email_address, self.email_password)
            return mail
            
        except Exception as e:
            logger.error(f"Error connecting to IMAP: {e}")
            raise
    
    def send_email(self, to_email: str, subject: str, body: str):
        """Send email response via SMTP"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = self.email_address
            msg['To'] = to_email
            msg['Subject'] = subject
            
            # Add body
            msg.attach(MIMEText(body, 'plain', 'utf-8'))
            
            # Create SSL context
            context = ssl.create_default_context()
            
            # Connect to SMTP server
            if self.smtp_port == 587:
                # STARTTLS connection
                server = smtplib.SMTP(self.smtp_host, self.smtp_port)
                server.starttls(context=context)
            elif self.smtp_port == 465:
                # SSL connection
                server = smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, context=context)
            else:
                # Plain connection
                server = smtplib.SMTP(self.smtp_host, self.smtp_port)
            
            # Login and send
            server.login(self.email_address, self.email_password)
            server.sendmail(self.email_address, to_email, msg.as_string())
            server.quit()
            
            logger.info(f"Email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return False
    
    def get_email_hash(self, msg_id: str, subject: str, sender: str) -> str:
        """Generate unique hash for email to track processing"""
        unique_string = f"{msg_id}_{subject}_{sender}"
        return hashlib.md5(unique_string.encode()).hexdigest()
    
    def check_new_emails(self):
        """Check for new emails and process them"""
        try:
            mail = self.connect_imap()
            mail.select('inbox')
            
            # Search for unread emails
            status, messages = mail.search(None, 'UNSEEN')
            
            if status == 'OK':
                email_ids = messages[0].split()
                
                for email_id in email_ids:
                    try:
                        self.process_email(mail, email_id)
                    except Exception as e:
                        logger.error(f"Error processing email {email_id}: {e}")
                        continue
            
            mail.close()
            mail.logout()
            
        except Exception as e:
            logger.error(f"Error checking emails: {e}")
    
    def process_email(self, mail, email_id):
        """Process a single email and send response"""
        try:
            # Fetch email
            status, msg_data = mail.fetch(email_id, '(RFC822)')
            
            if status != 'OK':
                return
            
            # Parse email
            raw_email = msg_data[0][1]
            msg = email.message_from_bytes(raw_email)
            
            # Extract email information
            sender = msg.get('From', '')
            subject = msg.get('Subject', '')
            msg_id = msg.get('Message-ID', '')
            
            # Decode subject if needed
            if subject:
                subject = str(decode_header(subject)[0][0])
            
            # Check if already processed
            email_hash = self.get_email_hash(msg_id, subject, sender)
            if email_hash in self.processed_emails:
                logger.debug(f"Email already processed: {subject}")
                return
            
            # Extract body
            body = ""
            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() == "text/plain":
                        body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                        break
            else:
                body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')
            
            # Clean body
            body = body.strip()
            
            # Skip if no body or if it's too short
            if not body or len(body) < 10:
                logger.debug(f"Skipping email with empty or too short body: {subject}")
                return
            
            # Skip auto-replies and system messages
            if any(keyword in subject.lower() for keyword in ['auto-reply', 'automatic', 'noreply', 'no-reply']):
                logger.debug(f"Skipping auto-reply: {subject}")
                return
            
            logger.info(f"Processing email from {sender}: {subject}")
            
            # Generate AI response
            ai_response = self.generate_response(body)
            
            # Format email response
            email_response = self.format_email_response(body, ai_response, sender)
            
            # Send response
            response_subject = f"Re: {subject}" if not subject.startswith('Re:') else subject
            
            if self.send_email(sender, response_subject, email_response):
                # Mark as processed
                self.processed_emails.add(email_hash)
                logger.info(f"Successfully processed and responded to email from {sender}")
            else:
                logger.error(f"Failed to send response to {sender}")
            
        except Exception as e:
            logger.error(f"Error processing email: {e}")
    
    def start_monitoring(self):
        """Start monitoring emails in a loop"""
        logger.info(f"Starting email monitoring (checking every {self.check_interval} seconds)...")
        
        while self.is_running:
            try:
                self.check_new_emails()
                time.sleep(self.check_interval)
                
            except KeyboardInterrupt:
                logger.info("Email monitoring stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait longer before retrying
    
    def start(self):
        """Start the email bot"""
        logger.info("Starting Docker-Mailserver Email Bot for Code du Travail...")
        
        # Load model
        logger.info("Loading fine-tuned AI model...")
        self.load_model()
        
        # Start monitoring
        self.is_running = True
        self.start_monitoring()
        
    def stop(self):
        """Stop the email bot"""
        logger.info("Stopping email bot...")
        self.is_running = False

def main():
    """Main function"""
    # Ensure logs directory exists
    os.makedirs('logs', exist_ok=True)
    
    try:
        bot = MailserverEmailBot()
        bot.start()
    except KeyboardInterrupt:
        logger.info("Email bot stopped by user")
    except Exception as e:
        logger.error(f"Email bot error: {e}")
        raise

if __name__ == '__main__':
    main() 