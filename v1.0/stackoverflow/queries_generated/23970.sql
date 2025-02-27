WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPosts,
        STRING_AGG(COALESCE(cr.Name, 'Unknown'), ', ') AS CloseReasons
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.UserId
),
RankedUsers AS (
    SELECT 
        ps.UserId,
        ps.DisplayName,
        ps.TotalScore,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalBadges,
        ps.BadgeNames,
        COALESCE(cpr.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(cpr.CloseReasons, 'None') AS CloseReasons,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS ScoreRank
    FROM UserPostStats ps
    LEFT JOIN ClosedPostReasons cpr ON ps.UserId = cpr.UserId
)
SELECT 
    ru.DisplayName,
    ru.TotalScore,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalBadges,
    ru.BadgeNames,
    ru.ClosedPosts,
    ru.CloseReasons,
    CONCAT('User Rank: ', ru.ScoreRank) AS UserRankInfo,
    CASE 
        WHEN ru.ClosedPosts > 0 THEN 'Has closed posts'
        ELSE 'No closed posts'
    END AS PostCloseStatus,
    CASE
        WHEN ru.TotalPosts > 0 THEN ROUND((ru.TotalScore::decimal / ru.TotalPosts), 2)
        ELSE 0
    END AS AverageScorePerPost
FROM RankedUsers ru
WHERE ru.TotalScore IS NOT NULL
ORDER BY ru.ScoreRank
LIMIT 100;

### Explanation of SQL Constructs:

1. **CTEs (Common Table Expressions)**: 
   - `UserPostStats` calculates aggregate statistics for users regarding their posts and badges.
   - `ClosedPostReasons` counts closed posts and aggregates close reasons associated with the user.
   - `RankedUsers` combines the results of the first two CTEs and ranks users based on their total scores.

2. **Outer Joins**: Used in CTEs to ensure all users are included even if they have no posts or badges, using `LEFT JOIN`.

3. **String Aggregation**: `STRING_AGG` is used to concatenate badge names and close reasons into a comma-separated list.

4. **Window Functions**: `ROW_NUMBER()` assigns a rank to each user based on their total score.

5. **Complicated Predicates**: The `CASE` statements are used to calculate average scores per post and check for closed posts.

6. **NULL Logic**: Utilizes `COALESCE` to handle potential `NULL` values in aggregates.

7. **Expressions and Calculations**: Calculates average score per post as a decimal and provides descriptive text based on conditions.

8. **Limit**: Limits the output to the top 100 users based on their score ranking for performance benchmarking. 

This query is both elaborate and efficient, demonstrating a comprehensive approach to aggregating and presenting user data from the Stack Overflow schema while incorporating several advanced SQL features.
