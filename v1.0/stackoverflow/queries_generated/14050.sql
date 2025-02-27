-- Performance benchmarking query: Count posts and their relationships with users, votes, and comments
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
