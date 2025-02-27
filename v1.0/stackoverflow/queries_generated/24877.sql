WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeValue
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgScore,
        ur.TotalBadgeValue,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS OverallRank
    FROM 
        UserRankings ur
        JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.Reputation IS NOT NULL 
        AND ur.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    ROUND(tu.AvgScore, 2) AS RoundedAvgScore,
    CASE 
        WHEN tu.TotalQuestions = 0 THEN 'No questions'
        ELSE CONCAT('Post ratio: ', ROUND(tu.TotalAnswers::decimal / NULLIF(tu.TotalQuestions, 0), 2))
    END AS PostRatio,
    COALESCE((
        SELECT 
            STRING_AGG(b.Name, ', ') 
        FROM 
            Badges b
        WHERE 
            b.UserId = tu.UserId
            AND b.Class = 1  -- Gold badges
    ), 'No Gold Badges') AS GoldBadges
FROM 
    TopUsers tu
WHERE 
    tu.OverallRank <= 10
ORDER BY 
    tu.OverallRank;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `UserRankings`: Computes user rankings based on reputation and total badge values.
   - `PostStats`: Aggregates statistics for posts per user, calculating total posts, questions, answers, and average score.
   - `TopUsers`: Combines the first two CTEs and filters users with above-average reputation, ranking them overall.

2. **Main Selection**:
   - Selects top users based on overall rankings, displaying relevant user information.
   - Determines the post ratio while handling possible division by zero using `NULLIF`.
   - Utilizes `STRING_AGG` to gather data on gold badges, with a fallback to 'No Gold Badges' if none exist.

3. **Aggregate Functions and Calculations**:
   - Implements `ROUND` to format statistics.
   - Uses `COALESCE` for handling NULL values effectively.

4. **Bizarre SQL Semantics**:
   - Use of `NULLIF` in the division prevents zeros from causing errors.
   - The conditional formatting of post ratios using `CASE` and `CONCAT` demonstrates creative use of string manipulation.

5. **Outer Joins & Aggregations**:
   - Left joins are used to include users even if they have no associated badges, showcasing the flexibility of outer joins in aggregating data without losing context.

This query captures a nuanced yet interesting part of user engagement in a forum-like environment, reflecting both performance and community contributions.
