
SELECT u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Users AS u
JOIN Posts AS p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
