-- Performance benchmarking query to analyze post engagement and user activity

WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.CommentCount,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
    GROUP BY 
        p.Id, u.Reputation, u.DisplayName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(v.BountyAmount) AS TotalBountySpent,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.Score,
    pe.CommentCount,
    pe.AnswerCount,
    pe.OwnerReputation,
    pe.OwnerDisplayName,
    pe.VoteCount,
    ua.UserId,
    ua.DisplayName AS UserDisplayName,
    ua.PostsCreated,
    ua.TotalBountySpent,
    ua.CommentsMade
FROM 
    PostEngagement pe
JOIN 
    UserActivity ua ON pe.OwnerUserId = ua.UserId
ORDER BY 
    pe.Score DESC, pe.ViewCount DESC;  -- Order by score and view count for performance metrics
