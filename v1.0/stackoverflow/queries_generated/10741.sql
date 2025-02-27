-- Performance Benchmarking Query
-- This query retrieves detailed information about posts, users, and their associated metrics for benchmarking query performance

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate,
    c.Id AS CommentId,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate,
    v.Id AS VoteId,
    v.VoteTypeId,
    v.CreationDate AS VoteCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the latest 100 posts for benchmarking
