SELECT u.DisplayName, p.Title, p.CreationDate, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Select only questions
ORDER BY p.ViewCount DESC
LIMIT 10; -- Get the top 10 most viewed questions
