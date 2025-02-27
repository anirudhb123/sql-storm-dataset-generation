
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
    p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE) 
GROUP BY
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName,
    u.Reputation,
    c.CommentCount,
    v.VoteCount
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
