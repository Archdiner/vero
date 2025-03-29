from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from models import User, RoommateMatch, MatchStatus

def compute_compatibility_score(user1: User, user2: User) -> float:
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

    # Factor 1: Age difference (assume max 10 years difference)
    if user1.age is not None and user2.age is not None:
        add_numeric_factor(user1.age, user2.age, max_diff=10, weight=0.1)

    # Factor 2: Smoking preference (boolean, weight 0.1)
    if user1.smoking_preference is not None and user2.smoking_preference is not None:
        add_factor(user1.smoking_preference == user2.smoking_preference, weight=0.1)

    # Factor 3: Drinking preference (boolean, weight 0.1)
    if user1.drinking_preference is not None and user2.drinking_preference is not None:
        add_factor(user1.drinking_preference == user2.drinking_preference, weight=0.1)

    # Factor 4: Pet preference (boolean, weight 0.1)
    if user1.pet_preference is not None and user2.pet_preference is not None:
        add_factor(user1.pet_preference == user2.pet_preference, weight=0.05)

    if user1.music_preference is not None and user2.music_preference is not None:
        add_factor(user1.music_preference == user2.music_preference, weight=0.05)

    # Factor 5: Cleanliness level (scale 1-10, weight 0.15)
    if user1.cleanliness_level is not None and user2.cleanliness_level is not None:
        add_numeric_factor(user1.cleanliness_level, user2.cleanliness_level, max_diff=9, weight=0.15)

    # Factor 6: Social preference (string, weight 0.1)
    if user1.social_preference and user2.social_preference:
        add_factor(user1.social_preference.lower() == user2.social_preference.lower(), weight=0.1)

    # Factor 7: Bedtime (time, weight 0.15; assume maximum acceptable difference is 120 minutes)
    if user1.bedtime and user2.bedtime:
        add_time_factor(user1.bedtime, user2.bedtime, max_diff_minutes=120, weight=0.15)

    # Factor 8: Budget range (integer, weight 0.1; assume max difference 3000)
    if user1.budget_range is not None and user2.budget_range is not None:
        add_numeric_factor(user1.budget_range, user2.budget_range, max_diff=3000, weight=0.1)

    # Factor 9: Move-in date (optional; weight 0.1; assume max difference 60 days)
    if user1.move_in_date and user2.move_in_date:
        add_date_factor(user1.move_in_date, user2.move_in_date, max_diff_days=60, weight=0.1)

    # Normalize score (if no factors are available, return 0)
    if total_weight > 0:
        return score_sum / total_weight
    else:
        return 0.0

def update_matches(current_user_id: int, db: Session) -> list:
    current_user = db.query(User).filter(User.id == current_user_id).first()
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Current user not found"
        )
    
    potential_users = db.query(User).filter(
        User.id != current_user_id,
        User.university == current_user.university
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
                match_status=MatchStatus.PENDING
            )
            db.add(new_match)
        
        # Build a dictionary of the candidate's data to return.
        results.append({
            "id": other.id,
            "fullname": other.fullname,
            "age": other.age,
            "gender": other.gender.value if hasattr(other, "gender") and other.gender else None,
            "major": other.major,
            "year_of_study": other.year_of_study,
            "bio": other.bio,
            "profile_picture": other.profile_picture,
            "compatibility_score": score
        })
    
    db.commit()
    return results
