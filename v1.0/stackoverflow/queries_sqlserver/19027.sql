
SELECT u.DisplayName, COUNT(p.Id) AS PostCount, SUM(ISNULL(p.Score, 0)) AS TotalScore
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
