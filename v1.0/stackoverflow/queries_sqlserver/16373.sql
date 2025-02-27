
SELECT p.Id, p.Title, p.CreationDate, u.DisplayName, t.TagName 
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN Tags t ON p.Tags LIKE '%' + t.TagName + '%'
WHERE p.PostTypeId = 1
GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, t.TagName
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
