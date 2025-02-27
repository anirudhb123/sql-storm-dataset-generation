
SELECT u.DisplayName, p.Title, p.CreationDate, t.TagName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE p.PostTypeId = 1  
GROUP BY u.DisplayName, p.Title, p.CreationDate, t.TagName
ORDER BY p.CreationDate DESC
LIMIT 10;
