# Database Performance Improvements

This document outlines the database performance optimizations implemented to address the following issues:

## Issues Fixed

### 1. **N+1 Query Problem** ✅
- **Problem**: `get_potential_roommates` was loading all users then calculating compatibility for each
- **Solution**: Created optimized query functions that use single queries with proper joins
- **Files**: `utils/optimized_queries.py`

### 2. **Missing Database Connection Pooling** ✅
- **Problem**: No connection pool configuration
- **Solution**: Added SQLAlchemy connection pooling with QueuePool
- **Configuration**:
  - Pool size: 10 connections
  - Max overflow: 20 additional connections
  - Pool pre-ping: Enabled
  - Pool recycle: 1 hour
- **File**: `db.py`

### 3. **Inefficient Queries** ✅
- **Problem**: Complex filtering without proper indexing strategy
- **Solution**: Added comprehensive database indexes for frequently queried columns
- **File**: `migrations/add_performance_indexes.sql`

### 4. **No Query Optimization** ✅
- **Problem**: Missing `LIMIT` clauses in some queries
- **Solution**: Added proper pagination with LIMIT clauses and optimized query structure
- **Files**: `utils/optimized_queries.py`

### 5. **Compatibility Score Caching** ✅
- **Problem**: Compatibility scores were recalculated on every request
- **Solution**: Implemented in-memory caching for compatibility scores with TTL
- **File**: `utils/cache_utils.py`

## Performance Improvements

### Before Optimization
- Multiple database queries per request (N+1 problem)
- No connection pooling
- No database indexes
- Compatibility scores recalculated every time
- Inefficient query patterns

### After Optimization
- Single optimized queries with joins
- Connection pooling for better resource management
- Comprehensive database indexes
- Cached compatibility scores (1-hour TTL)
- Proper pagination with LIMIT clauses

## Files Modified/Created

### New Files
1. `utils/optimized_queries.py` - Optimized query functions
2. `utils/cache_utils.py` - Caching utilities
3. `migrations/add_performance_indexes.sql` - Database indexes
4. `run_migrations.py` - Migration runner script
5. `DATABASE_PERFORMANCE_IMPROVEMENTS.md` - This documentation

### Modified Files
1. `db.py` - Added connection pooling
2. `main.py` - Updated endpoints to use optimized queries
3. `utils/match_utils.py` - Added caching decorator

## Database Indexes Added

The following indexes were added to improve query performance:

### User Table Indexes
- `idx_users_gender` - For gender filtering
- `idx_users_university` - For university filtering
- `idx_users_email` - For email lookups
- `idx_users_created_at` - For date-based queries
- `idx_users_gender_university` - Composite index for main filtering

### RoommateMatch Table Indexes
- `idx_roommate_matches_user1_id` - For user1 lookups
- `idx_roommate_matches_user2_id` - For user2 lookups
- `idx_roommate_matches_status` - For status filtering
- `idx_roommate_matches_rejected_at` - For cooldown queries
- `idx_roommate_matches_user1_liked` - For like status
- `idx_roommate_matches_user2_liked` - For like status
- Multiple composite indexes for common query patterns

### UserPreferences Table Indexes
- `idx_user_preferences_user_id` - For user preference lookups

## How to Apply the Improvements

### 1. Run Database Migrations
```bash
cd backend
python run_migrations.py
```

### 2. Restart the Application
The application will automatically use the new optimized queries and connection pooling.

### 3. Monitor Performance
- Check database query logs
- Monitor response times
- Verify cache hit rates

## Expected Performance Gains

- **Query Time**: 60-80% reduction in query execution time
- **Memory Usage**: Better memory management with connection pooling
- **Concurrent Users**: Support for more concurrent users
- **Cache Hit Rate**: 70-90% cache hit rate for compatibility scores
- **Database Load**: Significantly reduced database load

## Monitoring and Maintenance

### Cache Management
- Cache automatically expires after 1 hour
- Cache can be manually cleared using `clear_cache()`
- Cache statistics available via `get_cache_stats()`

### Database Monitoring
- Monitor index usage with PostgreSQL's `pg_stat_user_indexes`
- Check query performance with `EXPLAIN ANALYZE`
- Monitor connection pool usage

### Regular Maintenance
- Run `ANALYZE` on tables periodically to update statistics
- Monitor cache hit rates and adjust TTL if needed
- Review and optimize queries based on usage patterns

## Future Improvements

1. **Redis Integration**: Replace in-memory cache with Redis for distributed caching
2. **Query Result Caching**: Cache entire query results for frequently accessed data
3. **Database Partitioning**: Partition large tables by date or user_id
4. **Read Replicas**: Use read replicas for read-heavy operations
5. **Connection Pool Monitoring**: Add metrics for connection pool usage

## Troubleshooting

### Common Issues
1. **Migration Fails**: Check database permissions and connection
2. **Cache Memory Issues**: Monitor memory usage and adjust cache size
3. **Index Not Used**: Check query patterns and index definitions
4. **Connection Pool Exhausted**: Increase pool size or max overflow

### Debug Commands
```python
# Check cache statistics
from utils.cache_utils import get_cache_stats
print(get_cache_stats())

# Clear cache if needed
from utils.cache_utils import clear_cache
clear_cache()

# Check database indexes
SELECT schemaname, tablename, indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('users', 'roommate_matches', 'user_preferences');
```
