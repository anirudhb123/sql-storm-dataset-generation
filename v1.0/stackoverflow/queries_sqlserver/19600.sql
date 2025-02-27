
SELECT p.Title, p.CreationDate, u.DisplayName, b.Name as BadgeName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE p.PostTypeId = 1 
GROUP BY p.Title, p.CreationDate, u.DisplayName, b.Name
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
