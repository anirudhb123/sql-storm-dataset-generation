
SELECT p.Id AS PostId, 
       p.Title, 
       p.CreationDate, 
       u.DisplayName AS OwnerDisplayName, 
       p.Score, 
       p.Tags 
FROM Posts p 
JOIN Users u ON p.OwnerUserId = u.Id 
WHERE p.PostTypeId = 1 
GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.Tags 
ORDER BY p.Score DESC 
LIMIT 10;
