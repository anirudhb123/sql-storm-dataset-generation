SELECT u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  -- Filtering for questions
ORDER BY p.CreationDate DESC
LIMIT 10;  -- Limiting to the latest 10 questions
