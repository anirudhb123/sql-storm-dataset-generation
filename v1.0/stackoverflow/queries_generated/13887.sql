-- Performance benchmarking query
-- This query evaluates the performance of various operations by aggregating the number of posts, votes, and comments per user, and retrieving the most active users along with their post counts.
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT pc.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    CommentCount, 
    VoteCount
FROM 
    UserActivity
ORDER BY 
    PostCount DESC, 
    CommentCount DESC, 
    VoteCount DESC
LIMIT 100;  -- Adjust the limit as needed for benchmarking
