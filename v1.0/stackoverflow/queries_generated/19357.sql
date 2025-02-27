SELECT p.Title, p.CreationDate, u.DisplayName, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  -- We're interested in Questions
ORDER BY p.ViewCount DESC
LIMIT 10;  -- Retrieve the top 10 most viewed questions
