
SELECT Users.DisplayName, Posts.Title, Posts.CreationDate, Posts.ViewCount
FROM Users
JOIN Posts ON Users.Id = Posts.OwnerUserId
WHERE Posts.CreationDate >= '2023-01-01'
GROUP BY Users.DisplayName, Posts.Title, Posts.CreationDate, Posts.ViewCount
ORDER BY Posts.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
