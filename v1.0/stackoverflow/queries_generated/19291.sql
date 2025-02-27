SELECT u.DisplayName, u.Reputation, p.Title, p.CreationDate
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1 -- Only questions
ORDER BY u.Reputation DESC
LIMIT 10;
