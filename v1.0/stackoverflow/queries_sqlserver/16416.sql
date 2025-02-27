
SELECT Posts.Title, Users.DisplayName, Posts.CreationDate
FROM Posts
JOIN Users ON Posts.OwnerUserId = Users.Id
WHERE Posts.PostTypeId = 1
GROUP BY Posts.Title, Users.DisplayName, Posts.CreationDate
ORDER BY Posts.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
