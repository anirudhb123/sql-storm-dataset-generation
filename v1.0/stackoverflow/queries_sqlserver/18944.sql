
SELECT Users.DisplayName, Posts.Title, Posts.CreationDate
FROM Users
JOIN Posts ON Users.Id = Posts.OwnerUserId
WHERE Posts.PostTypeId = 1 
GROUP BY Users.DisplayName, Posts.Title, Posts.CreationDate
ORDER BY Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
