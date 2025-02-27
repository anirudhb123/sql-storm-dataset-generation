
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS HistoryCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
