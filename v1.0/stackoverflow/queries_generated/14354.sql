-- Performance benchmarking query for StackOverflow schema

-- This query retrieves a summary of posts along with user details and counts of their interactions
-- It will help assess the performance by aggregating data across multiple tables

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2022-01-01' -- Adjust date as needed for benchmarking
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit number of results for performance analysis
