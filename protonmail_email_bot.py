#!/usr/bin/env python3
"""
ProtonMail Email Bot for Code du Travail - Mistral 7B Fine-tuned Model

This bot monitors ProtonMail (via Bridge) for incoming questions and responds automatically
using the fine-tuned Mistral 7B model for French labor law questions.

Optimized for complete and precise responses.
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

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=getattr(logging, os.getenv('EMAIL_LOG_LEVEL', 'INFO')),
    handlers=[
        logging.FileHandler('logs/protonmail_email_bot.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ProtonMailBot:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = os.getenv('MODEL_NAME', "Pyzeur/Code-du-Travail-mistral-finetune")
        self.base_model_name = "mistralai/Mistral-7B-Instruct-v0.3"
        self.is_loading = False
        self.processed_emails = set()  # Track processed emails by hash
        
        # ProtonMail configuration (via Bridge)
        self.email_address = os.getenv('PROTONMAIL_ADDRESS')
        self.email_password = os.getenv('PROTONMAIL_PASSWORD')
        self.imap_host = os.getenv('PROTONMAIL_IMAP_HOST', '127.0.0.1')
        self.imap_port = int(os.getenv('PROTONMAIL_IMAP_PORT', '1143'))
        self.smtp_host = os.getenv('PROTONMAIL_SMTP_HOST', '127.0.0.1')
        self.smtp_port = int(os.getenv('PROTONMAIL_SMTP_PORT', '1025'))
        
        # AI Parameters optimized for complete and precise responses
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
        
        # Validate configuration
        if not self.email_address or not self.email_password:
            raise ValueError("PROTONMAIL_ADDRESS and PROTONMAIL_PASSWORD must be set in .env")
        
        logger.info(f"ProtonMail bot initialized for: {self.email_address}")
        logger.info(f"Device: {self.device}")
        logger.info(f"IMAP: {self.imap_host}:{self.imap_port}")
        logger.info(f"SMTP: {self.smtp_host}:{self.smtp_port}")
        logger.info(f"AI Parameters: tokens={self.max_tokens}, temp={self.temperature}, top_p={self.top_p}")
        
    def load_model(self):
        """Load the fine-tuned LoRA model"""
        if self.model is not None:
            return
            
        self.is_loading = True
        logger.info("Loading LoRA model for precise email responses...")
        
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
        """Generate response with optimized parameters for complete and precise answers"""
        if self.model is None or self.tokenizer is None:
            return "❌ Le modèle n'est pas encore chargé."
        
        try:
            # Clean and prepare the question
            question = question.strip()
            
            # Format prompt for Mistral with enhanced instructions for precision
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
            
            # Optimized generation parameters for complete and precise responses
            generation_config = {
                "max_new_tokens": self.max_tokens,
                "do_sample": True,
                "temperature": self.temperature,  # Lower for more precision
                "top_p": self.top_p,
                "top_k": self.top_k,
                "repetition_penalty": self.repetition_penalty,  # Higher to avoid repetition
                "pad_token_id": self.tokenizer.eos_token_id,
                "eos_token_id": self.tokenizer.eos_token_id,
                "use_cache": True,
                "no_repeat_ngram_size": 3,  # Avoid 3-gram repetitions
                "early_stopping": True
            }
            
            logger.info(f"Generating response with parameters: {generation_config}")
            
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
            
            logger.info(f"Generated response length: {len(response)} characters")
            return response
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return f"Erreur lors de la génération de la réponse: {str(e)}"
    
    def _clean_response(self, response: str) -> str:
        """Clean and format the AI response"""
        # Remove any remaining instruction markers
        response = re.sub(r'\[INST\].*?\[/INST\]', '', response, flags=re.DOTALL)
        response = re.sub(r'<s>|</s>', '', response)
        
        # Remove excessive whitespace
        response = re.sub(r'\n\s*\n\s*\n', '\n\n', response)
        response = response.strip()
        
        # Ensure proper formatting
        if not response.endswith('.'):
            response += '.'
        
        return response
    
    def format_email_response(self, question: str, ai_response: str, sender_email: str) -> str:
        """Format the response with professional introduction and footer for email"""
        
        # Professional introduction
        introduction = (
            f"Bonjour,\n\n"
            f"Merci pour votre question concernant le Code du Travail français. "
            f"Voici ma réponse détaillée basée sur ma connaissance du droit du travail :\n\n"
        )
        
        # Professional footer with signature and disclaimer
        footer = (
            f"\n\n{'='*60}\n"
            f"⚠️  CLAUSE DE NON-RESPONSABILITÉ\n\n"
            f"{self.disclaimer}\n\n"
            f"Pour toute question urgente ou complexe, nous vous recommandons "
            f"de consulter directement un professionnel du droit.\n\n"
            f"Cordialement,\n"
            f"{self.signature}\n"
            f"{'='*60}\n"
            f"Email automatique - Ne pas répondre directement à ce message\n"
            f"Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M')}"
        )
        
        return f"{introduction}{ai_response}{footer}"
    
    def connect_imap(self):
        """Connect to ProtonMail IMAP via Bridge"""
        try:
            mail = imaplib.IMAP4(self.imap_host, self.imap_port)
            mail.starttls()
            mail.login(self.email_address, self.email_password)
            logger.info("IMAP connection successful")
            return mail
        except Exception as e:
            logger.error(f"IMAP connection failed: {e}")
            raise
    
    def send_email(self, to_email: str, subject: str, body: str):
        """Send email response via ProtonMail SMTP Bridge"""
        try:
            msg = MIMEMultipart()
            msg['From'] = self.email_address
            msg['To'] = to_email
            msg['Subject'] = f"Re: {subject}" if not subject.startswith('Re:') else subject
            
            msg.attach(MIMEText(body, 'plain', 'utf-8'))
            
            # Connect to SMTP server
            server = smtplib.SMTP(self.smtp_host, self.smtp_port)
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
    
    def get_email_hash(self, msg_id: str, subject: str, sender: str) -> str:
        """Generate hash for email to avoid duplicate processing"""
        content = f"{msg_id}{subject}{sender}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def check_new_emails(self):
        """Check for new emails and process them"""
        try:
            mail = self.connect_imap()
            mail.select('INBOX')
            
            # Search for unread emails
            status, messages = mail.search(None, 'UNSEEN')
            
            if status == 'OK' and messages[0]:
                email_ids = messages[0].split()
                logger.info(f"Found {len(email_ids)} new emails")
                
                for email_id in email_ids:
                    try:
                        self.process_email(mail, email_id)
                    except Exception as e:
                        logger.error(f"Error processing email {email_id}: {e}")
                        
            mail.logout()
            
        except Exception as e:
            logger.error(f"Error checking emails: {e}")
    
    def process_email(self, mail, email_id):
        """Process a single email"""
        # Fetch email
        status, msg_data = mail.fetch(email_id, '(RFC822)')
        
        if status != 'OK':
            return
        
        # Parse email
        msg = email.message_from_bytes(msg_data[0][1])
        
        # Extract email details
        subject = decode_header(msg['Subject'])[0][0]
        if isinstance(subject, bytes):
            subject = subject.decode()
        
        sender = msg['From']
        msg_id = msg['Message-ID']
        
        # Generate hash to avoid duplicates
        email_hash = self.get_email_hash(msg_id, subject, sender)
        
        if email_hash in self.processed_emails:
            logger.info(f"Email already processed: {subject}")
            return
        
        # Extract email body
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body = part.get_payload(decode=True).decode()
                    break
        else:
            body = msg.get_payload(decode=True).decode()
        
        if not body.strip():
            logger.warning(f"Empty email body from {sender}")
            return
        
        logger.info(f"Processing email from {sender}: {subject}")
        logger.info(f"Email body preview: {body[:200]}...")
        
        # Generate AI response
        logger.info("Generating AI response...")
        ai_response = self.generate_response(body)
        
        # Format complete email response
        email_response = self.format_email_response(body, ai_response, sender)
        
        # Send response
        if self.send_email(sender, subject, email_response):
            self.processed_emails.add(email_hash)
            
            # Mark as read
            mail.store(email_id, '+FLAGS', '\\Seen')
            
            logger.info(f"Successfully processed and responded to email from {sender}")
        else:
            logger.error(f"Failed to send response to {sender}")
    
    def start_monitoring(self, check_interval=30):
        """Start monitoring emails"""
        logger.info(f"Starting email monitoring (checking every {check_interval}s)...")
        
        while True:
            try:
                self.check_new_emails()
                time.sleep(check_interval)
                
            except KeyboardInterrupt:
                logger.info("Email monitoring stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait longer on error
    
    def start(self):
        """Start the ProtonMail bot"""
        logger.info("Starting ProtonMail Bot for Code du Travail...")
        
        # Load model
        logger.info("Loading AI model...")
        self.load_model()
        
        # Test connections
        logger.info("Testing ProtonMail connections...")
        try:
            mail = self.connect_imap()
            mail.logout()
            logger.info("IMAP connection test successful")
        except Exception as e:
            logger.error(f"IMAP connection test failed: {e}")
            raise
        
        logger.info("ProtonMail bot ready! Starting email monitoring...")
        self.start_monitoring()

def main():
    """Main function"""
    try:
        # Create logs directory
        os.makedirs('logs', exist_ok=True)
        
        bot = ProtonMailBot()
        bot.start()
        
    except KeyboardInterrupt:
        logger.info("ProtonMail bot stopped by user")
    except Exception as e:
        logger.error(f"ProtonMail bot error: {e}")
        raise

if __name__ == '__main__':
    main()
