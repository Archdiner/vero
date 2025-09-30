-- Database Performance Optimization Indexes
-- Run this script to add indexes for better query performance

-- Indexes for User table frequently queried columns
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender);
CREATE INDEX IF NOT EXISTS idx_users_university ON users(university);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Composite index for the main filtering query in get_potential_roommates
CREATE INDEX IF NOT EXISTS idx_users_gender_university ON users(gender, university);

-- Indexes for RoommateMatch table
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user1_id ON roommate_matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user2_id ON roommate_matches(user2_id);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_status ON roommate_matches(match_status);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_rejected_at ON roommate_matches(rejected_at);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user1_liked ON roommate_matches(user1_liked);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user2_liked ON roommate_matches(user2_liked);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user1_status ON roommate_matches(user1_id, match_status);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user2_status ON roommate_matches(user2_id, match_status);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user1_liked_status ON roommate_matches(user1_id, user1_liked, match_status);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_user2_liked_status ON roommate_matches(user2_id, user2_liked, match_status);
CREATE INDEX IF NOT EXISTS idx_roommate_matches_rejected_status ON roommate_matches(match_status, rejected_at) WHERE match_status = 'rejected';

-- Index for UserPreferences table
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- Partial indexes for better performance on specific conditions
CREATE INDEX IF NOT EXISTS idx_roommate_matches_pending_user1 ON roommate_matches(user1_id) WHERE match_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_roommate_matches_pending_user2 ON roommate_matches(user2_id) WHERE match_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_roommate_matches_matched_users ON roommate_matches(user1_id, user2_id) WHERE match_status = 'matched';

-- Index for compatibility score ordering
CREATE INDEX IF NOT EXISTS idx_roommate_matches_compatibility_score ON roommate_matches(compatibility_score DESC);

-- Analyze tables to update statistics
ANALYZE users;
ANALYZE roommate_matches;
ANALYZE user_preferences;
