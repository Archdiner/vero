from typing import Dict, Any, Optional
import time
import logging
from functools import wraps

logger = logging.getLogger(__name__)

# Simple in-memory cache for compatibility scores
# In production, consider using Redis or Memcached
_compatibility_cache: Dict[str, Dict[str, Any]] = {}
_cache_ttl = 3600  # 1 hour TTL

def get_cache_key(user1_id: int, user2_id: int) -> str:
    """Generate a cache key for compatibility score between two users."""
    # Always use the smaller ID first for consistent caching
    return f"compat_{min(user1_id, user2_id)}_{max(user1_id, user2_id)}"

def get_cached_compatibility_score(user1_id: int, user2_id: int) -> Optional[float]:
    """Get cached compatibility score if it exists and is not expired."""
    cache_key = get_cache_key(user1_id, user2_id)
    
    if cache_key in _compatibility_cache:
        cached_data = _compatibility_cache[cache_key]
        if time.time() - cached_data['timestamp'] < _cache_ttl:
            logger.debug(f"Cache hit for compatibility score: {user1_id} <-> {user2_id}")
            return cached_data['score']
        else:
            # Remove expired entry
            del _compatibility_cache[cache_key]
            logger.debug(f"Cache expired for compatibility score: {user1_id} <-> {user2_id}")
    
    return None

def cache_compatibility_score(user1_id: int, user2_id: int, score: float) -> None:
    """Cache compatibility score with timestamp."""
    cache_key = get_cache_key(user1_id, user2_id)
    _compatibility_cache[cache_key] = {
        'score': score,
        'timestamp': time.time()
    }
    logger.debug(f"Cached compatibility score: {user1_id} <-> {user2_id} = {score}")

def invalidate_user_cache(user_id: int) -> None:
    """Invalidate all cache entries for a specific user."""
    keys_to_remove = []
    for cache_key in _compatibility_cache.keys():
        if str(user_id) in cache_key:
            keys_to_remove.append(cache_key)
    
    for key in keys_to_remove:
        del _compatibility_cache[key]
    
    logger.debug(f"Invalidated {len(keys_to_remove)} cache entries for user {user_id}")

def clear_cache() -> None:
    """Clear all cached data."""
    _compatibility_cache.clear()
    logger.info("Compatibility cache cleared")

def get_cache_stats() -> Dict[str, Any]:
    """Get cache statistics."""
    current_time = time.time()
    active_entries = 0
    expired_entries = 0
    
    for cached_data in _compatibility_cache.values():
        if current_time - cached_data['timestamp'] < _cache_ttl:
            active_entries += 1
        else:
            expired_entries += 1
    
    return {
        'total_entries': len(_compatibility_cache),
        'active_entries': active_entries,
        'expired_entries': expired_entries,
        'cache_ttl': _cache_ttl
    }

def cached_compatibility_score(func):
    """
    Decorator to cache compatibility score calculations.
    Use this to wrap the compute_compatibility_score function.
    """
    @wraps(func)
    def wrapper(user1, user2):
        user1_id = getattr(user1, 'id', None)
        user2_id = getattr(user2, 'id', None)
        
        if user1_id and user2_id:
            # Try to get from cache first
            cached_score = get_cached_compatibility_score(user1_id, user2_id)
            if cached_score is not None:
                return cached_score
            
            # Calculate and cache the result
            score = func(user1, user2)
            cache_compatibility_score(user1_id, user2_id, score)
            return score
        else:
            # Fallback to direct calculation if no IDs available
            return func(user1, user2)
    
    return wrapper
