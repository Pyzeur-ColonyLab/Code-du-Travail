#!/usr/bin/env python3
"""
Script de vérification de santé pour le bot Telegram Code du Travail
"""

import os
import sys
import psutil
import subprocess
from pathlib import Path
import json
from datetime import datetime

def check_process():
    """Vérifier si le processus du bot est en cours d'exécution"""
    pid_file = Path('bot.pid')
    if not pid_file.exists():
        return False, "Fichier PID non trouvé"
    
    try:
        with open(pid_file) as f:
            pid = int(f.read().strip())
        
        if psutil.pid_exists(pid):
            process = psutil.Process(pid)
            return True, f"Processus actif (PID: {pid}, RAM: {process.memory_info().rss // 1024 // 1024}MB)"
        else:
            return False, f"Processus PID {pid} non trouvé"
    except Exception as e:
        return False, f"Erreur lecture PID: {e}"

def check_disk_space():
    """Vérifier l'espace disque disponible"""
    try:
        usage = psutil.disk_usage('.')
        free_gb = usage.free // (1024**3)
        total_gb = usage.total // (1024**3)
        percent_used = (usage.used / usage.total) * 100
        
        if percent_used > 90:
            return False, f"Espace disque critique: {percent_used:.1f}% utilisé"
        elif percent_used > 80:
            return True, f"Avertissement espace disque: {percent_used:.1f}% utilisé ({free_gb}GB libres)"
        else:
            return True, f"Espace disque OK: {free_gb}GB libres sur {total_gb}GB"
    except Exception as e:
        return False, f"Erreur vérification disque: {e}"

def check_memory():
    """Vérifier l'utilisation mémoire"""
    try:
        memory = psutil.virtual_memory()
        if memory.percent > 90:
            return False, f"Mémoire critique: {memory.percent}% utilisée"
        elif memory.percent > 80:
            return True, f"Avertissement mémoire: {memory.percent}% utilisée"
        else:
            return True, f"Mémoire OK: {memory.percent}% utilisée ({memory.available // 1024 // 1024}MB libres)"
    except Exception as e:
        return False, f"Erreur vérification mémoire: {e}"

def check_gpu():
    """Vérifier l'état du GPU si disponible"""
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=memory.used,memory.total,utilization.gpu', '--format=csv,noheader,nounits'],
            capture_output=True, text=True, timeout=10
        )
        
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            gpu_info = []
            
            for i, line in enumerate(lines):
                mem_used, mem_total, gpu_util = map(int, line.split(', '))
                mem_percent = (mem_used / mem_total) * 100
                
                if mem_percent > 90:
                    status = "CRITIQUE"
                elif mem_percent > 80:
                    status = "AVERTISSEMENT"
                else:
                    status = "OK"
                
                gpu_info.append(f"GPU{i}: {status} - Mém: {mem_percent:.1f}%, Util: {gpu_util}%")
            
            return True, "; ".join(gpu_info)
        else:
            return True, "GPU non disponible ou nvidia-smi non installé"
    except subprocess.TimeoutExpired:
        return False, "Timeout lors de la vérification GPU"
    except FileNotFoundError:
        return True, "nvidia-smi non trouvé (pas de GPU NVIDIA)"
    except Exception as e:
        return False, f"Erreur vérification GPU: {e}"

def check_config():
    """Vérifier la configuration"""
    env_file = Path('.env')
    if not env_file.exists():
        return False, "Fichier .env manquant"
    
    # Vérifier les variables importantes sans les exposer
    try:
        from dotenv import load_dotenv
        load_dotenv()
        
        token = os.getenv('TELEGRAM_BOT_TOKEN')
        if not token:
            return False, "TELEGRAM_BOT_TOKEN non défini"
        
        return True, "Configuration OK"
    except ImportError:
        return False, "python-dotenv non installé"
    except Exception as e:
        return False, f"Erreur configuration: {e}"

def check_log_file():
    """Vérifier le fichier de log"""
    log_file = Path('bot.log')
    if not log_file.exists():
        return True, "Pas de fichier log (bot pas encore démarré)"
    
    try:
        size_mb = log_file.stat().st_size / (1024 * 1024)
        if size_mb > 100:  # Log > 100MB
            return False, f"Fichier log volumineux: {size_mb:.1f}MB"
        else:
            return True, f"Fichier log: {size_mb:.1f}MB"
    except Exception as e:
        return False, f"Erreur lecture log: {e}"

def main():
    """Fonction principale de vérification"""
    print("🏥 Vérification de santé du bot Code du Travail")
    print("=" * 50)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print()
    
    checks = [
        ("Processus bot", check_process),
        ("Espace disque", check_disk_space),
        ("Mémoire RAM", check_memory),
        ("GPU", check_gpu),
        ("Configuration", check_config),
        ("Fichier log", check_log_file)
    ]
    
    results = {}
    all_ok = True
    
    for name, check_func in checks:
        try:
            ok, message = check_func()
            status = "✅ OK" if ok else "❌ ERREUR"
            print(f"{status} {name}: {message}")
            
            results[name] = {
                "status": "ok" if ok else "error",
                "message": message
            }
            
            if not ok:
                all_ok = False
        except Exception as e:
            print(f"❌ ERREUR {name}: Exception - {e}")
            results[name] = {
                "status": "error",
                "message": f"Exception: {e}"
            }
            all_ok = False
    
    print()
    print(f"État global: {'✅ SAIN' if all_ok else '❌ PROBLÈMES DÉTECTÉS'}")
    
    # Sauvegarder le rapport en JSON si demandé
    if len(sys.argv) > 1 and sys.argv[1] == "--json":
        report = {
            "timestamp": datetime.now().isoformat(),
            "global_status": "healthy" if all_ok else "unhealthy",
            "checks": results
        }
        
        with open("health_report.json", "w") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        print(f"\n📄 Rapport sauvegardé dans health_report.json")
    
    # Code de sortie pour les scripts automatisés
    sys.exit(0 if all_ok else 1)

if __name__ == "__main__":
    main()
