from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from models import User, RoommateMatch, MatchStatus, UserPreferences
from datetime import datetime, timedelta

def compute_compatibility_score(user1: User, user2: User) -> float:
    """
    Calculate a compatibility score between two users based on their profiles.
    
    Factors with highest importance:
    1. Gender (same gender)
    2. Cleanliness level
    3. Sleep/wake schedule
    4. Noise preference
    5. Guest policy
    6. Room type preference
    7. Religious/cultural considerations
    """
    score_sum = 0.0
    total_weight = 0.0

    # Helper to add a factor if available.
    def add_factor(condition: bool, weight: float):
        nonlocal score_sum, total_weight
        score_sum += (1.0 if condition else 0.0) * weight
        total_weight += weight

    def add_numeric_factor(val1, val2, max_diff: float, weight: float):
        nonlocal score_sum, total_weight
        if val1 is not None and val2 is not None:
            diff = abs(val1 - val2)
            factor_score = max(0, 1 - diff / max_diff)
            score_sum += factor_score * weight
            total_weight += weight

    def add_time_factor(time1, time2, max_diff_minutes: float, weight: float):
        nonlocal score_sum, total_weight
        if time1 and time2:
            t1 = time1.hour * 60 + time1.minute
            t2 = time2.hour * 60 + time2.minute
            diff = abs(t1 - t2)
            factor_score = max(0, 1 - diff / max_diff_minutes)
            score_sum += factor_score * weight
            total_weight += weight

    def add_date_factor(date1, date2, max_diff_days: float, weight: float):
        nonlocal score_sum, total_weight
        if date1 and date2:
            diff_days = abs((date1 - date2).days)
            factor_score = max(0, 1 - diff_days / max_diff_days)
            score_sum += factor_score * weight
            total_weight += weight
            
    def add_preference_factor(val1, val2, exact_match_weight=0.1, no_match_score=0.0):
        """Add score for string-based preferences like guest_policy, room_type, etc."""
        nonlocal score_sum, total_weight
        if val1 and val2:
            if val1 == val2:
                score_sum += exact_match_weight
            else:
                score_sum += no_match_score
            total_weight += exact_match_weight

    # MOST IMPORTANT: Gender matching (same gender strongly preferred)
    if user1.gender and user2.gender:
        # Gender is extremely important, high weight (0.3)
        add_factor(user1.gender == user2.gender, weight=0.3)

    # VERY IMPORTANT: Cleanliness level compatibility
    if user1.cleanliness_level is not None and user2.cleanliness_level is not None:
        # Cleanliness is very important, high weight (0.2)
        # Smaller max_diff (5 instead of 9) to emphasize closer cleanliness matching
        add_numeric_factor(user1.cleanliness_level, user2.cleanliness_level, max_diff=5, weight=0.2)

    # VERY IMPORTANT: Sleep and wake schedule compatibility
    if user1.sleep_time and user2.sleep_time:
        # Sleep schedule is very important, high weight (0.15)
        add_time_factor(user1.sleep_time, user2.sleep_time, max_diff_minutes=90, weight=0.15)
    
    if user1.wake_time and user2.wake_time:
        # Wake time is also important (0.1)
        add_time_factor(user1.wake_time, user2.wake_time, max_diff_minutes=90, weight=0.1)
    
    # IMPORTANT: Guest policy compatibility
    if user1.guest_policy and user2.guest_policy:
        # Guest policy is important (0.15)
        # Exact match gets full points, non-match gets zero
        add_preference_factor(user1.guest_policy, user2.guest_policy, exact_match_weight=0.15)
    
    # IMPORTANT: Room type preference compatibility
    if user1.room_type_preference and user2.room_type_preference:
        # Room type is moderately important (0.1)
        # Exact match gets full points, "any" also gets partial credit
        if user1.room_type_preference == "any" or user2.room_type_preference == "any":
            add_factor(True, weight=0.1 * 0.7)  # 70% score for "any" match
        else:
            add_preference_factor(user1.room_type_preference, user2.room_type_preference, exact_match_weight=0.1)
    
    # IMPORTANT: Religious/cultural consideration compatibility
    if user1.religious_preference and user2.religious_preference:
        # Religious preference is moderately important (0.1)
        if user1.religious_preference == "none" or user2.religious_preference == "none":
            add_factor(True, weight=0.1 * 0.8)  # 80% score for "none" match
        else:
            add_preference_factor(user1.religious_preference, user2.religious_preference, exact_match_weight=0.1)
    
    # Dietary restrictions compatibility
    if user1.dietary_restrictions and user2.dietary_restrictions:
        # Dietary restrictions are somewhat important (0.05)
        if user1.dietary_restrictions == "none" or user2.dietary_restrictions == "none":
            add_factor(True, weight=0.05 * 0.8)  # 80% score for "none" match
        else:
            add_preference_factor(user1.dietary_restrictions, user2.dietary_restrictions, exact_match_weight=0.05)

    # Less critical factors with lower weights
    if user1.age is not None and user2.age is not None:
        add_numeric_factor(user1.age, user2.age, max_diff=10, weight=0.05)

    if user1.smoking_preference is not None and user2.smoking_preference is not None:
        add_factor(user1.smoking_preference == user2.smoking_preference, weight=0.05)

    if user1.drinking_preference is not None and user2.drinking_preference is not None:
        add_factor(user1.drinking_preference == user2.drinking_preference, weight=0.05)

    if user1.pet_preference is not None and user2.pet_preference is not None:
        add_factor(user1.pet_preference == user2.pet_preference, weight=0.05)

    if user1.music_preference is not None and user2.music_preference is not None:
        add_factor(user1.music_preference == user2.music_preference, weight=0.05)

    if user1.social_preference and user2.social_preference:
        add_factor(user1.social_preference == user2.social_preference, weight=0.05)

    if user1.budget_range is not None and user2.budget_range is not None:
        add_numeric_factor(user1.budget_range, user2.budget_range, max_diff=1000, weight=0.05)

    if user1.move_in_date and user2.move_in_date:
        add_date_factor(user1.move_in_date, user2.move_in_date, max_diff_days=30, weight=0.05)

    # Calculate and return the weighted score
    if total_weight > 0:
        return min(1.0, score_sum / total_weight) * 100  # Convert to percentage (0-100)
    else:
        return 50.0  # Default midpoint score if no factors could be compared

def update_matches(current_user_id: int, db: Session) -> list:
    current_user = db.query(User).filter(User.id == current_user_id).first()
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Current user not found"
        )
    
    # Get potential roommates, filtering for same gender as per user's requirement
    potential_users = db.query(User).filter(
        User.id != current_user_id,
        User.university == current_user.university,
        User.gender == current_user.gender  # Same gender filter
    ).all()

    results = []
    for other in potential_users:
        # Compute compatibility score between current user and candidate.
        score = compute_compatibility_score(current_user, other)
        
        # Check if a match record already exists between the current user and this candidate.
        existing_match = db.query(RoommateMatch).filter(
            or_(
                and_(RoommateMatch.user1_id == current_user_id, RoommateMatch.user2_id == other.id),
                and_(RoommateMatch.user1_id == other.id, RoommateMatch.user2_id == current_user_id)
            )
        ).first()
        
        if existing_match:
            # Update the score.
            existing_match.compatibility_score = score
        else:
            # Create a new match record.
            new_match = RoommateMatch(
                user1_id=current_user_id,
                user2_id=other.id,
                compatibility_score=score,
                match_status=MatchStatus.pending
            )
            db.add(new_match)
        
        # Build a dictionary of the candidate's data to return.
        results.append({
            "id": other.id,
            "fullname": other.fullname,
            "age": other.age,
            "gender": other.gender.value if hasattr(other, "gender") and other.gender else None,
            "university": other.university,
            "major": other.major,
            "year_of_study": other.year_of_study,
            "bio": other.bio,
            "profile_picture": other.profile_picture,
            "compatibility_score": score,
            "cleanliness_level": other.cleanliness_level,
            "guest_policy": other.guest_policy,
            "room_type_preference": other.room_type_preference,
            "religious_preference": other.religious_preference,
            "dietary_restrictions": other.dietary_restrictions,
            "sleep_time": other.sleep_time.strftime("%H:%M") if other.sleep_time else None,
            "wake_time": other.wake_time.strftime("%H:%M") if other.wake_time else None
        })
    
    db.commit()
    
    # Sort by compatibility score
    results.sort(key=lambda x: x["compatibility_score"], reverse=True)
    return results

def update_user_preferences(user_id: int, swiped_user_id: int, liked: bool, db: Session):
    """
    Update a user's preferences based on swiping behavior.
    
    Args:
        user_id: The ID of the user doing the swiping
        swiped_user_id: The ID of the user being swiped on
        liked: Whether the swipe was a like (True) or dislike (False)
        db: Database session
    """
    # Get the users
    user = db.query(User).filter(User.id == user_id).first()
    swiped_user = db.query(User).filter(User.id == swiped_user_id).first()
    
    if not user or not swiped_user:
        return
    
    # Get or create user preferences
    user_prefs = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    if not user_prefs:
        user_prefs = UserPreferences(user_id=user_id)
        db.add(user_prefs)
        db.commit()
    
    # Define weight change based on like/dislike
    # Likes influence preferences more than dislikes
    weight_change = 0.05 if liked else -0.03
    
    # Update cleanliness preference if available
    if swiped_user.cleanliness_level is not None:
        new_pref = user_prefs.preferred_cleanliness + (swiped_user.cleanliness_level - user_prefs.preferred_cleanliness) * weight_change
        user_prefs.preferred_cleanliness = max(1, min(10, new_pref))  # Keep within 1-10 range
    
    # Update guest policy weights if available
    if swiped_user.guest_policy:
        # Initialize if not exists
        if not user_prefs.guest_policy_weights:
            user_prefs.guest_policy_weights = {}
        
        # Get current weight or default to 0.5
        current_weight = user_prefs.guest_policy_weights.get(swiped_user.guest_policy, 0.5)
        
        # Update weight (likes increase, dislikes decrease)
        new_weight = current_weight + weight_change
        user_prefs.guest_policy_weights[swiped_user.guest_policy] = max(0.1, min(1.0, new_weight))
    
    # Update room type weights if available
    if swiped_user.room_type_preference:
        # Initialize if not exists
        if not user_prefs.room_type_weights:
            user_prefs.room_type_weights = {}
        
        # Get current weight or default to 0.5
        current_weight = user_prefs.room_type_weights.get(swiped_user.room_type_preference, 0.5)
        
        # Update weight
        new_weight = current_weight + weight_change
        user_prefs.room_type_weights[swiped_user.room_type_preference] = max(0.1, min(1.0, new_weight))
    
    # Update religious preference weights if available
    if swiped_user.religious_preference:
        # Initialize if not exists
        if not user_prefs.religious_weights:
            user_prefs.religious_weights = {}
        
        # Get current weight or default to 0.5
        current_weight = user_prefs.religious_weights.get(swiped_user.religious_preference, 0.5)
        
        # Update weight
        new_weight = current_weight + weight_change
        user_prefs.religious_weights[swiped_user.religious_preference] = max(0.1, min(1.0, new_weight))
    
    # Update dietary restriction weights if available
    if swiped_user.dietary_restrictions:
        # Initialize if not exists
        if not user_prefs.dietary_weights:
            user_prefs.dietary_weights = {}
        
        # Get current weight or default to 0.5
        current_weight = user_prefs.dietary_weights.get(swiped_user.dietary_restrictions, 0.5)
        
        # Update weight
        new_weight = current_weight + weight_change
        user_prefs.dietary_weights[swiped_user.dietary_restrictions] = max(0.1, min(1.0, new_weight))
    
    # Commit the changes
    db.commit()
