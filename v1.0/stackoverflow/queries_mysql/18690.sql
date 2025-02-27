
SELECT u.DisplayName, u.Reputation, p.Title, p.CreationDate 
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, u.Reputation, p.Title, p.CreationDate
ORDER BY p.CreationDate DESC
LIMIT 10;
