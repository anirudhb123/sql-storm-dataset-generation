-- Performance Benchmarking Query

-- This query retrieves various statistics for posts along with their associated vote counts, comments, and user reputation.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id) AS TotalVotes,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    VoteCount,
    CommentCount,
    TotalVotes,
    OwnerReputation
FROM 
    PostStats
ORDER BY 
    ViewCount DESC
LIMIT 100;
