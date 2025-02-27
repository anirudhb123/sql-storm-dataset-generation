-- Performance Benchmarking Query
-- This query retrieves the top 10 users by reputation, 
-- along with their post and comment counts, average score, 
-- and the total number of badges earned, 
-- aiming to analyze user engagement on the platform.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(AVG(p.Score), 0) AS AveragePostScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.CommentCount,
    us.AveragePostScore,
    us.BadgeCount
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC
LIMIT 10;
