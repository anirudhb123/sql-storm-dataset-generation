WITH RECURSIVE UserReputationCTE (UserId, Reputation, Level) AS (
    SELECT u.Id, u.Reputation, 
           CASE 
               WHEN u.Reputation >= 10000 THEN 'High'
               WHEN u.Reputation BETWEEN 5000 AND 9999 THEN 'Medium'
               ELSE 'Low' 
           END AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL
    UNION ALL
    SELECT u.Id, u.Reputation, 
           CASE 
               WHEN u.Reputation >= 10000 THEN 'High'
               WHEN u.Reputation BETWEEN 5000 AND 9999 THEN 'Medium'
               ELSE 'Low' 
           END AS Level
    FROM Users u
    JOIN UserReputationCTE cte ON u.Reputation < cte.Reputation
)

SELECT 
    u.DisplayName,
    COALESCE(b.Count, 0) AS BadgeCount,
    COALESCE(p.ViewCount, 0) AS TotalViews,
    SUM(v.BountyAmount) AS TotalBounties,
    COUNT(DISTINCT c.Id) AS CommentCount,
    CASE 
        WHEN ur.Level = 'High' THEN 'Elite Contributor'
        WHEN ur.Level = 'Medium' THEN 'Regular Contributor'
        ELSE 'Novice Contributor' 
    END AS ContributorStatus
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges count
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 9 -- BountyClose
LEFT JOIN Comments c ON u.Id = c.UserId
JOIN UserReputationCTE ur ON u.Id = ur.UserId
WHERE u.CreationDate < NOW() - INTERVAL '1 year'
AND u.Reputation IS NOT NULL
GROUP BY u.DisplayName, ur.Level, b.Count, p.ViewCount
HAVING COUNT(DISTINCT c.Id) > 5
ORDER BY TotalBounties DESC, TotalViews DESC;

This SQL query combines multiple constructs including a recursive CTE to determine user reputation levels, various left joins for badge and post count, and aggregates user contributions with grouping and conditional case statements. It filters out users based on creation date and requires a minimum number of comments to be included in the final set, while ordering results by contributions, offering a clear performance metric for active users.
