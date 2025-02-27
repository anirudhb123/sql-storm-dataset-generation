
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    COALESCE(a.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.VoteCount, 0) AS VoteCount,
    u.Reputation AS UserReputation,
    u.Location AS UserLocation,
    u.CreationDate AS UserCreationDate
FROM 
    Posts p
LEFT JOIN 
    (SELECT 
         ParentId, 
         COUNT(*) AS AcceptedAnswerCount 
     FROM Posts 
     WHERE PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL 
     GROUP BY ParentId) a ON p.Id = a.ParentId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    a.AcceptedAnswerCount, 
    c.CommentCount, 
    v.VoteCount, 
    u.Reputation, 
    u.Location, 
    u.CreationDate
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
