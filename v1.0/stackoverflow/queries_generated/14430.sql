-- Benchmarking query to measure the performance of different actions on the Stack Overflow schema

-- This query will retrieve statistics about posts, their associated users, and comments,
-- which can help in identifying performance bottlenecks related to post retrieval, user reputation, and comment counts.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    c.Id AS CommentId,
    c.Score AS CommentScore,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Replace with your date filter as needed
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Adjust limit as needed for your performance testing
