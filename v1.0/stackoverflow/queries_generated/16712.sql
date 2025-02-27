SELECT u.Id AS UserId, u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1 -- Selecting only Questions
ORDER BY p.CreationDate DESC
LIMIT 10;
