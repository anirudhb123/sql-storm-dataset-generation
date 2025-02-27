WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostWithFlags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        CASE WHEN p.AggrFlag > 0 THEN 'Flagged' ELSE 'Not Flagged' END AS FlagStatus,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS AggrFlag
        FROM Votes
        WHERE VoteTypeId IN (10, 12)  -- Consider only close and delete votes
        GROUP BY PostId
    ) AS postFlags ON p.Id = postFlags.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days' -- Recent posts
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.PostCount,
    pwf.PostId,
    pwf.Title,
    pwf.Score,
    pwf.FlagStatus
FROM UserStats us
FULL OUTER JOIN PostWithFlags pwf ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pwf.PostId LIMIT 1)
WHERE us.Reputation IS NOT NULL OR pwf.PostId IS NOT NULL
ORDER BY us.Reputation DESC, pwf.Score DESC
LIMIT 50;

This query involves several advanced SQL constructs to benchmark both the performance and complexity. It starts with Common Table Expressions (CTEs) to calculate user statistics and post flags. It uses different kinds of joins (LEFT, FULL OUTER) and a correlated subquery to join Users and Posts based on calculated fields. The query incorporates window functions (ROW_NUMBER) and complicated conditions in COALESCE function along with filtering. Additionally, it handles NULL logic in the final WHERE clause. The constructed query should be capable of revealing performance disparities stemming from its complexity and data structure intricacies in the provided schema.
