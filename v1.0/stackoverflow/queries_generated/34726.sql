WITH RECURSIVE UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER(PARTITION BY u.Id ORDER BY COALESCE(v.CreationDate, u.CreationDate) DESC) AS rn
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        DATEDIFF(NOW(), u.LastAccessDate) AS DaysSinceLastAccess
    FROM Users u
    WHERE u.LastAccessDate > NOW() - INTERVAL '90' DAY
),

TopUsers AS (
    SELECT 
        au.UserId,
        au.Reputation,
        COALESCE(ur.TotalBounty, 0) AS TotalBounty
    FROM ActiveUsers au
    LEFT JOIN UserReputationHistory ur ON au.UserId = ur.UserId
    WHERE ur.rn = 1
)

SELECT 
    u.DisplayName,
    u.Reputation,
    tu.TotalBounty,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews,
    AVG(CASE WHEN c.Score IS NULL THEN 0 ELSE c.Score END) AS AvgCommentScore
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN TopUsers tu ON u.Id = tu.UserId
WHERE u.Reputation >= 1000
GROUP BY u.DisplayName, u.Reputation, tu.TotalBounty
HAVING COUNT(p.Id) > 5 AND AVG(c.Score) > 0
ORDER BY u.Reputation DESC, TotalViews DESC
LIMIT 10;

This query consists of several common table expressions (CTEs) to encapsulate various logic:

1. `UserReputationHistory`: Computes total bounty for each user.
2. `ActiveUsers`: Filters users who accessed their accounts in the last 90 days.
3. `TopUsers`: Combines the active user data with their bounty history.

The final `SELECT` retrieves users with a minimum reputation, filters by their activity, and provides aggregated statistics about their posts and comments.
