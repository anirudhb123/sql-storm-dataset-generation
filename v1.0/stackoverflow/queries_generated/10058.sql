-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
), UserScore AS (
    SELECT 
        ua.UserId,
        SUM(CASE 
                WHEN rp.PostId IS NOT NULL THEN 1 
                ELSE 0 
            END) AS ActivityScore
    FROM UserActivity ua
    LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId
    GROUP BY ua.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalBounty,
    us.ActivityScore
FROM UserActivity ua
LEFT JOIN UserScore us ON ua.UserId = us.UserId
ORDER BY ua.Reputation DESC, us.ActivityScore DESC
LIMIT 100;
