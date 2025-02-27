-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the basic statistics of posts and their associated users,
-- as well as the related comments and votes for assessing performance.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(v.VoteCount, 0) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount 
     FROM 
         Votes 
     GROUP BY 
         PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Consider posts created in the last 30 days
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit the output for performance reasons
