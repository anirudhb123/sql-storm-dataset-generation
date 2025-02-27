SELECT p.Title, u.DisplayName AS OwnerName, p.CreationDate, p.Score, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 -- Fetch only questions
ORDER BY p.Score DESC
LIMIT 10; -- Get top 10 questions by score
