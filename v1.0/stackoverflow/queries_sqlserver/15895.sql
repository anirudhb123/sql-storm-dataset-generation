
SELECT u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
