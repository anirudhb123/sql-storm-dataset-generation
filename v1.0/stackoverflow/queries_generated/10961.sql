-- Performance Benchmarking Query

-- This query retrieves a summary of posts, user information, and associated votes and comments to measure performance loading related data.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.Tags,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    c.CommentCount,
    v.VoteCount,
    ph.EditHistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount
     FROM Comments
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount
     FROM Votes
     GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS EditHistoryCount
     FROM PostHistory
     GROUP BY PostId) ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Example date condition for filtering posts
ORDER BY 
    p.CreationDate DESC;  -- Order by newest posts first
