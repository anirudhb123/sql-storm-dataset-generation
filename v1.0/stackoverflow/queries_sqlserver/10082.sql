
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
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
    u.Reputation, u.DisplayName, v.vote_count, c.comment_count
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
