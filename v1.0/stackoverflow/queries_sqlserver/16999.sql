
SELECT TOP 10 u.DisplayName, 
              u.Reputation, 
              p.Title, 
              p.CreationDate 
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC;
