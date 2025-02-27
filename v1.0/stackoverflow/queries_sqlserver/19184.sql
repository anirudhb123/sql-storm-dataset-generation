
SELECT p.Id, p.Title, p.CreationDate, COUNT(c.Id) AS CommentCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id, p.Title, p.CreationDate
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
