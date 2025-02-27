
SELECT u.DisplayName, COUNT(p.Id) AS TotalPosts
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
