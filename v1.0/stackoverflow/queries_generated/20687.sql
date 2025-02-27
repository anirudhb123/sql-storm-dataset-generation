WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(u.Reputation) OVER () AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users) 
        AND u.CreationDate < NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        u.Id
),
QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score,
        COALESCE(ph.CloseReasonId, 'Not Closed') AS CloseReason,
        COUNT(DISTINCT c.Id) AS NumberOfComments,
        MAX(pb.Name) AS BestPostByBadge
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1
    LEFT JOIN 
        (SELECT PostId, 
                COUNT(DISTINCT Id) AS BadgeCount
         FROM Badges
         GROUP BY PostId) pb ON p.Id = pb.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, ph.CloseReasonId
),
FinalReport AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.TotalBounties,
        qs.QuestionId,
        qs.Title,
        qs.Score,
        qs.CloseReason,
        qs.NumberOfComments,
        RANK() OVER (PARTITION BY ua.UserId ORDER BY qs.Score DESC) AS RankByScore
    FROM 
        UserActivity ua
    JOIN 
        QuestionStats qs ON ua.QuestionCount > 0
    WHERE 
        ua.AnswerCount > 0
)

SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.QuestionCount,
    fr.AnswerCount,
    fr.TotalBounties,
    fr.QuestionId,
    fr.Title,
    fr.Score,
    fr.CloseReason,
    fr.NumberOfComments,
    CASE 
        WHEN fr.RankByScore = 1 THEN 'Top Performer'
        ELSE 'Regular'
    END AS PerformanceBadge
FROM 
    FinalReport fr
WHERE 
    fr.RankByScore <= 3
ORDER BY 
    fr.UserId, fr.Score DESC;

### Explanation of the Query:
1. **CTEs (Common Table Expressions)**:
   - `UserActivity`: It aggregates user activity focused on users creating questions and answers, only including users with above-average reputation and who signed up over a year ago. It calculates the sum of questions and answers, total bounties, comment count, and the average reputation for comparison.
   - `QuestionStats`: Pulls question statistics, linking posts to their badges and checking for closed status, collecting data on comment counts and badges earned.
   - `FinalReport`: Joins the two CTEs to report user-centric insights, filtering users who have both created questions and answers.

2. **Computations**: Uses conditional aggregates, averaging, and window functions (RANK) to determine user performance.

3. **Bizarre SQL Semantics**:
   - Incorporates NULL logic and aggregation (e.g., using COALESCE to handle potential NULLs).
   - Uses semi-obscure ranking logic based on dynamically aggregated score calculations to assign performance badges for top users.

4. **Advanced Filtering**: The final result set strictly limits the output to top rank users by score, filtered further by user activity to reflect an active community engagement beyond simple post statistics. 

This query serves not merely as a performance benchmark; it illustrates intricate SQL capabilities with sophisticated logic in a contextually meaningful manner.
