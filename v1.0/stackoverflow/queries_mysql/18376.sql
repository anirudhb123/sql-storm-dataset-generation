
SELECT u.Id AS UserId, u.DisplayName, p.Id AS PostId, p.Title, p.CreationDate
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1
GROUP BY u.Id, u.DisplayName, p.Id, p.Title, p.CreationDate
ORDER BY p.CreationDate DESC
LIMIT 10;
