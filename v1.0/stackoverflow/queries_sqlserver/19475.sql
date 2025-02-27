
SELECT p.Id, p.Title, p.ViewCount, u.DisplayName, u.Reputation
FROM Posts AS p
JOIN Users AS u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 
ORDER BY p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
