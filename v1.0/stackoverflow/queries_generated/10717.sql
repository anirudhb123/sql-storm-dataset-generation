-- Performance Benchmarking Query

-- This query aims to measure the time taken to retrieve posts along with their associated data, including the number of votes and comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN a.Id END) AS AnswerCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.CreationDate >= '2020-01-01'  -- Filter for posts created since 2020
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;  -- Order by creation date
