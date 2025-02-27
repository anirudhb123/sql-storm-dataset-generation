
SELECT u.DisplayName, COUNT(p.Id) AS PostCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE u.Reputation > 100
GROUP BY u.DisplayName
ORDER BY PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
