from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, text
from models import User, RoommateMatch, MatchStatus, UserPreferences
from utils.match_utils import compute_compatibility_score
from datetime import timedelta
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

def get_potential_roommates_optimized(
    current_user_id: int,
    offset: int = 0,
    limit: int = 10,
    db: Session = None
) -> List[Dict[str, Any]]:
    """
    Optimized version of get_potential_roommates that uses a single query
    with proper joins to eliminate N+1 query problems.
    """
    
    # Get current user with a single query
    current_user = db.query(User).filter(User.id == current_user_id).first()
    if not current_user:
        return []
    
    # Ensure user preferences exist
    user_prefs = db.query(UserPreferences).filter(UserPreferences.user_id == current_user_id).first()
    if not user_prefs:
        user_prefs = UserPreferences(user_id=current_user_id)
        db.add(user_prefs)
        db.commit()
    
    # Calculate cooldown date
    cooldown_days = user_prefs.rejection_cooldown
    cooldown_date = func.now() - timedelta(days=cooldown_days)
    
    # Single optimized query to get all excluded user IDs
    excluded_users_query = db.query(
        func.coalesce(
            func.case(
                (RoommateMatch.user1_id == current_user_id, RoommateMatch.user2_id),
                else_=RoommateMatch.user1_id
            ),
            0
        ).label('excluded_user_id')
    ).filter(
        or_(
            # Rejected users in cooldown period
            and_(
                or_(
                    RoommateMatch.user1_id == current_user_id,
                    RoommateMatch.user2_id == current_user_id
                ),
                RoommateMatch.match_status == MatchStatus.rejected,
                RoommateMatch.rejected_at > cooldown_date
            ),
            # Already matched users
            and_(
                or_(
                    RoommateMatch.user1_id == current_user_id,
                    RoommateMatch.user2_id == current_user_id
                ),
                RoommateMatch.match_status == MatchStatus.matched
            ),
            # Users already liked by current user (but not those who liked current user)
            and_(
                RoommateMatch.user1_id == current_user_id,
                RoommateMatch.user1_liked == True,
                RoommateMatch.match_status == MatchStatus.pending,
                RoommateMatch.user2_liked == False  # Exclude if they also liked you
            )
        )
    ).subquery()
    
    # Get excluded user IDs
    excluded_user_ids = [row.excluded_user_id for row in db.query(excluded_users_query).all()]
    
    # Main query to get potential matches with a single database hit
    # This query uses proper indexing and LIMIT for pagination
    potential_matches = db.query(User).filter(
        User.id != current_user_id,
        User.gender == current_user.gender,
        ~User.id.in_(excluded_user_ids) if excluded_user_ids else True
    ).limit(limit * 3).all()  # Get 3x the limit to account for compatibility filtering
    
    logger.info(f"Found {len(potential_matches)} potential matches after filtering")
    
    # Calculate compatibility scores and build results
    results = []
    for user in potential_matches:
        if user:
            try:
                compatibility_score = compute_compatibility_score(current_user, user)
                
                results.append({
                    "id": user.id,
                    "fullname": user.fullname,
                    "age": user.age,
                    "gender": user.gender.value if user.gender else None,
                    "university": user.university,
                    "major": user.major,
                    "year_of_study": user.year_of_study,
                    "bio": user.bio,
                    "profile_picture": user.profile_picture,
                    "compatibility_score": compatibility_score,
                    "budget_range": user.budget_range,
                    "cleanliness_level": user.cleanliness_level,
                    "social_preference": user.social_preference.value if user.social_preference else None,
                    "smoking_preference": user.smoking_preference,
                    "drinking_preference": user.drinking_preference,
                    "pet_preference": user.pet_preference,
                    "music_preference": user.music_preference,
                    "guest_policy": user.guest_policy,
                    "room_type_preference": user.room_type_preference,
                    "religious_preference": user.religious_preference,
                    "dietary_restrictions": user.dietary_restrictions,
                    "sleep_time": user.sleep_time.strftime("%H:%M") if user.sleep_time else None,
                    "wake_time": user.wake_time.strftime("%H:%M") if user.wake_time else None
                })
            except Exception as e:
                logger.error(f"Error calculating compatibility for user {user.id}: {e}")
                continue
    
    # Sort by compatibility score (highest first)
    results.sort(key=lambda x: x["compatibility_score"], reverse=True)
    
    # Apply pagination
    paginated_results = results[offset:offset + limit]
    
    logger.info(f"Returning {len(paginated_results)} results for offset {offset}, limit {limit}")
    return paginated_results


def get_matches_optimized(
    current_user_id: int,
    include_preferences: bool = False,
    db: Session = None
) -> List[Dict[str, Any]]:
    """
    Optimized version of get_matches that uses a single query with joins.
    """
    
    # Single query to get all matches with user data
    matches_query = db.query(
        RoommateMatch,
        User.id.label('other_user_id'),
        User.fullname,
        User.age,
        User.gender,
        User.major,
        User.year_of_study,
        User.bio,
        User.profile_picture,
        User.university,
        User.instagram,
        User.budget_range,
        User.cleanliness_level,
        User.social_preference,
        User.smoking_preference,
        User.drinking_preference,
        User.pet_preference,
        User.music_preference,
        User.guest_policy,
        User.room_type_preference,
        User.religious_preference,
        User.dietary_restrictions,
        User.sleep_time,
        User.wake_time
    ).join(
        User,
        or_(
            and_(RoommateMatch.user1_id == current_user_id, RoommateMatch.user2_id == User.id),
            and_(RoommateMatch.user2_id == current_user_id, RoommateMatch.user1_id == User.id)
        )
    ).filter(
        RoommateMatch.match_status == MatchStatus.matched
    ).all()
    
    response = []
    for row in matches_query:
        match = row.RoommateMatch
        user_data = {
            "id": row.other_user_id,
            "fullname": row.fullname,
            "age": row.age,
            "gender": row.gender.value if row.gender else None,
            "major": row.major,
            "year_of_study": row.year_of_study,
            "bio": row.bio,
            "profile_picture": row.profile_picture,
            "compatibility_score": match.compatibility_score,
            "university": row.university,
            "instagram": row.instagram,
            "created_at": match.created_at.isoformat() if match.created_at else None,
            "match_status": match.match_status.value
        }
        
        if include_preferences:
            preference_data = {
                "budget_range": row.budget_range,
                "cleanliness_level": row.cleanliness_level,
                "social_preference": row.social_preference.value if row.social_preference else None,
                "smoking_preference": row.smoking_preference,
                "drinking_preference": row.drinking_preference,
                "pet_preference": row.pet_preference,
                "music_preference": row.music_preference,
                "guest_policy": row.guest_policy,
                "room_type_preference": row.room_type_preference,
                "religious_preference": row.religious_preference,
                "dietary_restrictions": row.dietary_restrictions,
                "sleep_time": row.sleep_time.strftime("%H:%M") if row.sleep_time else None,
                "wake_time": row.wake_time.strftime("%H:%M") if row.wake_time else None
            }
            user_data.update(preference_data)
        
        response.append(user_data)
    
    return response


def get_user_profile_optimized(
    user_id: int,
    current_user_id: int = None,
    include_preferences: bool = False,
    db: Session = None
) -> Dict[str, Any]:
    """
    Optimized version of get_user_profile that uses a single query.
    """
    
    # Single query to get user data
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None
    
    user_data = {
        "id": user.id,
        "fullname": user.fullname,
        "profile_picture": user.profile_picture,
        "instagram": user.instagram,
        "university": user.university,
        "age": user.age,
        "gender": user.gender.value if user.gender else None,
        "major": user.major,
        "year_of_study": user.year_of_study,
        "bio": user.bio
    }
    
    if include_preferences:
        # Calculate compatibility score if this is not the current user
        compatibility_score = None
        if user_id != current_user_id and current_user_id:
            current_user = db.query(User).filter(User.id == current_user_id).first()
            if current_user:
                compatibility_score = compute_compatibility_score(current_user, user)
        
        preference_data = {
            "budget_range": user.budget_range,
            "cleanliness_level": user.cleanliness_level,
            "social_preference": user.social_preference.value if user.social_preference else None,
            "smoking_preference": user.smoking_preference,
            "drinking_preference": user.drinking_preference,
            "pet_preference": user.pet_preference,
            "music_preference": user.music_preference,
            "guest_policy": user.guest_policy,
            "room_type_preference": user.room_type_preference,
            "religious_preference": user.religious_preference,
            "dietary_restrictions": user.dietary_restrictions,
            "sleep_time": user.sleep_time.strftime("%H:%M") if user.sleep_time else None,
            "wake_time": user.wake_time.strftime("%H:%M") if user.wake_time else None
        }
        
        if compatibility_score is not None:
            preference_data["compatibility_score"] = compatibility_score
            
        user_data.update(preference_data)
    
    return user_data
