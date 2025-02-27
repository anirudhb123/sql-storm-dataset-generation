SELECT u.DisplayName, p.Title, p.CreationDate
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1  -- Selecting only questions
ORDER BY p.CreationDate DESC
LIMIT 10;
