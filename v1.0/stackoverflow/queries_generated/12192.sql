-- Performance Benchmark Query

-- This query retrieves various statistics about posts, users, comments, and votes to evaluate performance in the Stack Overflow schema.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryEntries,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS TotalVotes 
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS t
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;  -- Order by the most recently created posts
