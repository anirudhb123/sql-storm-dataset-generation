-- Performance Benchmarking Query

-- This query will benchmark the retrieval of posts along with user details, 
-- count of votes, and tags associated with the posts, along with created date,
-- to analyze query response times and execution efficiency.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, '<>')) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate > '2020-01-01' -- Filtering for posts created after 2020
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC; -- Order posts by newest first
