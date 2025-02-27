-- Performance Benchmarking Query
-- This query retrieves user metrics, including their reputation, activity frequency, and number of posts, along with their associated badges

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.CreationDate))) AS AvgAccountAge,  -- average age of accounts in seconds
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ua.UserId,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.BadgeCount,
    ua.AvgAccountAge,
    ua.VoteCount
FROM 
    UserActivity ua
ORDER BY 
    ua.Reputation DESC, ua.PostCount DESC;
