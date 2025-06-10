#!/usr/bin/env python3
"""
Script de monitoring simple pour le bot Telegram Code du Travail
"""

import time
import psutil
import subprocess
import json
from datetime import datetime
from pathlib import Path
import argparse
import os

class SimpleMonitor:
    def __init__(self):
        self.thresholds = {
            "memory_percent": 90,
            "disk_percent": 85,
            "cpu_percent": 95,
            "gpu_memory_percent": 90,
            "log_size_mb": 100
        }
        
    def get_bot_pid(self):
        """Récupérer le PID du bot"""
        pid_file = Path('bot.pid')
        if pid_file.exists():
            try:
                with open(pid_file) as f:
                    return int(f.read().strip())
            except:
                pass
        return None
    
    def is_bot_running(self):
        """Vérifier si le bot est en cours d'exécution"""
        pid = self.get_bot_pid()
        return pid is not None and psutil.pid_exists(pid)
    
    def get_system_stats(self):
        """Récupérer les statistiques système"""
        stats = {
            "timestamp": datetime.now().isoformat(),
            "bot_running": self.is_bot_running(),
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory": psutil.virtual_memory()._asdict(),
            "disk": psutil.disk_usage('.')._asdict(),
        }
        
        # Statistiques GPU si disponible
        try:
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu', 
                 '--format=csv,noheader,nounits'],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpu_stats = []
                for line in lines:
                    mem_used, mem_total, gpu_util, temp = map(int, line.split(', '))
                    gpu_stats.append({
                        "memory_used": mem_used,
                        "memory_total": mem_total,
                        "memory_percent": (mem_used / mem_total) * 100,
                        "utilization": gpu_util,
                        "temperature": temp
                    })
                stats["gpus"] = gpu_stats
        except:
            stats["gpus"] = []
        
        # Statistiques du processus bot
        if stats["bot_running"]:
            try:
                pid = self.get_bot_pid()
                process = psutil.Process(pid)
                stats["bot_process"] = {
                    "memory_mb": process.memory_info().rss // 1024 // 1024,
                    "cpu_percent": process.cpu_percent(),
                    "create_time": process.create_time(),
                    "uptime_seconds": time.time() - process.create_time()
                }
            except:
                stats["bot_process"] = None
        
        # Taille du fichier log
        log_file = Path('bot.log')
        if log_file.exists():
            stats["log_size_mb"] = log_file.stat().st_size / (1024 * 1024)
        
        return stats
    
    def check_alerts(self, stats):
        """Vérifier les seuils et retourner les alertes"""
        alerts = []
        
        # Vérifier si le bot tourne
        if not stats["bot_running"]:
            alerts.append("❌ Bot arrêté ou non fonctionnel")
        
        # Vérifier la mémoire
        if stats["memory"]["percent"] > self.thresholds["memory_percent"]:
            alerts.append(f"⚠️ Mémoire critique: {stats['memory']['percent']:.1f}%")
        
        # Vérifier le disque
        disk_percent = (stats["disk"]["used"] / stats["disk"]["total"]) * 100
        if disk_percent > self.thresholds["disk_percent"]:
            alerts.append(f"⚠️ Espace disque critique: {disk_percent:.1f}%")
        
        # Vérifier le CPU
        if stats["cpu_percent"] > self.thresholds["cpu_percent"]:
            alerts.append(f"⚠️ CPU critique: {stats['cpu_percent']:.1f}%")
        
        # Vérifier le GPU
        for i, gpu in enumerate(stats.get("gpus", [])):
            if gpu["memory_percent"] > self.thresholds["gpu_memory_percent"]:
                alerts.append(f"⚠️ GPU{i} mémoire critique: {gpu['memory_percent']:.1f}%")
        
        # Vérifier la taille du log
        if stats.get("log_size_mb", 0) > self.thresholds["log_size_mb"]:
            alerts.append(f"⚠️ Fichier log volumineux: {stats['log_size_mb']:.1f}MB")
        
        return alerts
    
    def format_uptime(self, seconds):
        """Formater le temps de fonctionnement"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        return f"{hours}h{minutes:02d}m"
    
    def print_status(self, stats):
        """Afficher le statut du système"""
        print("📊 Monitoring Bot Code du Travail")
        print("=" * 40)
        print(f"🕐 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Statut du bot
        if stats["bot_running"]:
            print("✅ Bot: En cours d'exécution")
            if stats.get("bot_process"):
                uptime = self.format_uptime(stats["bot_process"]["uptime_seconds"])
                print(f"   ⏱️  Uptime: {uptime}")
                print(f"   💾 RAM: {stats['bot_process']['memory_mb']}MB")
                print(f"   🔄 CPU: {stats['bot_process']['cpu_percent']:.1f}%")
        else:
            print("❌ Bot: Arrêté")
        
        print()
        
        # Ressources système
        print("🖥️  Système:")
        print(f"   💾 RAM: {stats['memory']['percent']:.1f}% ({stats['memory']['used'] // 1024**3}GB / {stats['memory']['total'] // 1024**3}GB)")
        print(f"   💿 Disque: {(stats['disk']['used'] / stats['disk']['total'] * 100):.1f}% ({stats['disk']['free'] // 1024**3}GB libres)")
        print(f"   🔄 CPU: {stats['cpu_percent']:.1f}%")
        
        # GPU
        for i, gpu in enumerate(stats.get("gpus", [])):
            print(f"   🎮 GPU{i}: {gpu['memory_percent']:.1f}% mém, {gpu['utilization']}% util, {gpu['temperature']}°C")
        
        # Fichier log
        if stats.get("log_size_mb"):
            print(f"   📄 Log: {stats['log_size_mb']:.1f}MB")
        
        print()
        
        # Alertes
        alerts = self.check_alerts(stats)
        if alerts:
            print("🚨 ALERTES:")
            for alert in alerts:
                print(f"   {alert}")
        else:
            print("✅ Aucune alerte")
    
    def monitor_once(self):
        """Effectuer une vérification unique"""
        stats = self.get_system_stats()
        self.print_status(stats)
        alerts = self.check_alerts(stats)
        return len(alerts) == 0
    
    def monitor_continuous(self, interval=60):
        """Monitoring continu"""
        print(f"🔄 Monitoring continu (intervalle: {interval}s)")
        print("Appuyez sur Ctrl+C pour arrêter")
        print()
        
        try:
            while True:
                self.monitor_once()
                print(f"\n⏳ Prochaine vérification dans {interval}s...\n")
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Monitoring arrêté")

def main():
    parser = argparse.ArgumentParser(description='Monitoring du bot Code du Travail')
    parser.add_argument('--continuous', '-c', action='store_true', help='Monitoring continu')
    parser.add_argument('--interval', '-i', type=int, default=60, help='Intervalle en secondes (défaut: 60)')
    parser.add_argument('--json', action='store_true', help='Sortie en format JSON')
    
    args = parser.parse_args()
    
    monitor = SimpleMonitor()
    
    if args.json:
        stats = monitor.get_system_stats()
        alerts = monitor.check_alerts(stats)
        output = {
            "stats": stats,
            "alerts": alerts,
            "healthy": len(alerts) == 0
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
    elif args.continuous:
        monitor.monitor_continuous(args.interval)
    else:
        healthy = monitor.monitor_once()
        exit(0 if healthy else 1)

if __name__ == "__main__":
    main()
