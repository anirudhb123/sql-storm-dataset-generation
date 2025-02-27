-- Performance benchmarking query to analyze Post and associated Votes, Comments, and Users

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(v.vote_count, 0) AS VoteCount,
    COALESCE(c.comment_count, 0) AS CommentCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS vote_count 
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS comment_count 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- filter posts created in 2023
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 100; -- limit to top 100 posts for performance benchmarking
