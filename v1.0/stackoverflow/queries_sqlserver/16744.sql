
SELECT u.DisplayName, p.Title, p.CreationDate, t.TagName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN Tags t ON p.Tags LIKE '%' + t.TagName + '%'
WHERE p.PostTypeId = 1  
GROUP BY u.DisplayName, p.Title, p.CreationDate, t.TagName
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
