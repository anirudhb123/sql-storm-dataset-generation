
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
    IFNULL(c.CommentCount, 0) AS CommentCount,
    IFNULL(v.VoteCount, 0) AS VoteCount,
    IFNULL(ph.EditHistoryCount, 0) AS EditHistoryCount
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
    p.CreationDate >= '2023-01-01'  
ORDER BY 
    p.CreationDate DESC;
