import os
import time
import psutil
import torch
import logging
import py3nvml as nvml
from pathlib import Path
from functools import lru_cache
from cachetools import TTLCache
from typing import Dict, Any, Optional

# Initialize logging
logger = logging.getLogger(__name__)

class ResourceMonitor:
    def __init__(self):
        self.process = psutil.Process()
    
    def log_usage(self) -> Dict[str, float]:
        """Log current resource usage"""
        try:
            cpu_percent = self.process.cpu_percent()
            memory_info = self.process.memory_info()
            memory_percent = self.process.memory_percent()
            
            if torch.cuda.is_available():
                gpu_memory_allocated = torch.cuda.memory_allocated() / 1024**3  # GB
                gpu_memory_reserved = torch.cuda.memory_reserved() / 1024**3    # GB
            else:
                gpu_memory_allocated = 0
                gpu_memory_reserved = 0
            
            usage = {
                'cpu_percent': cpu_percent,
                'memory_used_gb': memory_info.rss / 1024**3,
                'memory_percent': memory_percent,
                'gpu_memory_allocated_gb': gpu_memory_allocated,
                'gpu_memory_reserved_gb': gpu_memory_reserved
            }
            
            logger.info(f"Resource usage: {usage}")
            return usage
            
        except Exception as e:
            logger.error(f"Error monitoring resources: {str(e)}")
            return {}

class NetworkVolumeManager:
    def __init__(self):
        self.volume_path = os.getenv('RUNPOD_VOLUME_PATH', '/runpod-volume')
    
    def ensure_path(self, path: str) -> bool:
        """Ensure a path exists in the network volume"""
        try:
            full_path = os.path.join(self.volume_path, path)
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            return True
        except Exception as e:
            logger.error(f"Error ensuring path {path}: {str(e)}")
            return False

class ModelOptimizer:
    @staticmethod
    def get_optimal_settings() -> Dict[str, Any]:
        """Get optimal model settings based on available resources"""
        if not torch.cuda.is_available():
            return {
                'precision': torch.float32,
                'attention_mode': None,
                'batch_size': 1
            }
            
        vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        
        if vram_gb >= 24:
            return {
                'precision': torch.float16,
                'attention_mode': 'xformers',
                'batch_size': 4
            }
        elif vram_gb >= 16:
            return {
                'precision': torch.float16,
                'attention_mode': 'xformers',
                'batch_size': 2
            }
        else:
            return {
                'precision': torch.float16,
                'attention_mode': 'sdp',
                'batch_size': 1
            }
    
    @staticmethod
    def optimize_for_inference(model: torch.nn.Module) -> torch.nn.Module:
        """Optimize model for inference"""
        if not torch.cuda.is_available():
            return model
            
        model.eval()
        if hasattr(model, 'enable_xformers_memory_efficient_attention'):
            model.enable_xformers_memory_efficient_attention()
        
        # Optimize transformer attention
        if hasattr(torch.nn.functional, 'scaled_dot_product_attention'):
            torch.backends.cuda.enable_mem_efficient_sdp()
        
        return model

def setup_environment():
    """Set up optimal environment settings"""
    try:
        # CUDA optimizations
        if torch.cuda.is_available():
            # Set optimal CUDA settings
            torch.backends.cuda.matmul.allow_tf32 = True
            torch.backends.cudnn.benchmark = True
            torch.backends.cudnn.deterministic = False
            
            # Log CUDA info
            logger.info(f"CUDA available: {torch.cuda.get_device_name(0)}")
            logger.info(f"CUDA memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
        
        # Set process priority
        try:
            psutil.Process().nice(10)
        except Exception:
            pass
        
        logger.info("Environment setup completed")
        
    except Exception as e:
        logger.error(f"Error setting up environment: {str(e)}")