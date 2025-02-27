
SELECT Posts.Title, Users.DisplayName, Posts.CreationDate
FROM Posts
JOIN Users ON Posts.OwnerUserId = Users.Id
WHERE Posts.PostTypeId = 1
GROUP BY Posts.Title, Users.DisplayName, Posts.CreationDate
ORDER BY Posts.CreationDate DESC
LIMIT 10;
