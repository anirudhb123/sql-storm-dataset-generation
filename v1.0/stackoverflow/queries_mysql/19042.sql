
SELECT Users.DisplayName, Posts.Title, Posts.CreationDate
FROM Posts
JOIN Users ON Posts.OwnerUserId = Users.Id
WHERE Posts.PostTypeId = 1 
GROUP BY Users.DisplayName, Posts.Title, Posts.CreationDate
ORDER BY Posts.CreationDate DESC
LIMIT 10;
