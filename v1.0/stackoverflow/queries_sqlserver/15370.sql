
SELECT u.DisplayName, 
       p.Title, 
       p.CreationDate, 
       p.Score, 
       COUNT(c.Id) AS CommentCount
FROM Users u
JOIN Posts p ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON c.PostId = p.Id
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
