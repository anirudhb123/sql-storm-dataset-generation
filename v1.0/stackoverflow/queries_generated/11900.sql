-- Performance benchmarking query for StackOverflow schema

-- This query evaluates the time taken to retrieve various details about posts,
-- along with their associated comments and votes, merging in user and post history details
-- to assess query performance across multiple joined tables.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ph.UserDisplayName AS LastEditorDisplayName,
    ph.LastEditDate,
    p.Tags
FROM 
    Posts AS p
LEFT JOIN 
    Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
LEFT JOIN 
    Votes AS v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory AS ph ON p.LastEditorUserId = ph.UserId AND p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in the year 2023
GROUP BY 
    p.Id, u.DisplayName, ph.UserDisplayName, ph.LastEditDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit results for benchmarking
