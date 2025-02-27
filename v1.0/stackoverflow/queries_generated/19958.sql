SELECT p.Title, u.DisplayName, p.CreationDate, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  -- Only select questions
ORDER BY p.CreationDate DESC
LIMIT 10;  -- Get the most recent 10 questions
