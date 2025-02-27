-- Performance Benchmarking SQL Query

-- This query retrieves a summary of the most active users based on the number of posts, votes, and comments.
-- It also fetches user reputation and total score from their posts to evaluate their overall contribution.
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.CreationDate IS NOT NULL) AS VoteCount,
        SUM(p.Score) AS TotalScore,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    VoteCount,
    TotalScore,
    Reputation
FROM 
    UserActivity
ORDER BY 
    PostCount DESC, VoteCount DESC, TotalScore DESC
LIMIT 10;
