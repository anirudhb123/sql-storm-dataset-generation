
SELECT Users.DisplayName, COUNT(Posts.Id) AS PostCount
FROM Users
JOIN Posts ON Users.Id = Posts.OwnerUserId
GROUP BY Users.DisplayName
ORDER BY PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
