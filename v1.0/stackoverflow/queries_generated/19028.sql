SELECT u.Id, u.DisplayName, COUNT(p.Id) AS PostCount, SUM(v.CreationDate IS NOT NULL) AS VoteCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.Id, u.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
