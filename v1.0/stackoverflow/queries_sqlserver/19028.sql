
SELECT u.Id, u.DisplayName, COUNT(p.Id) AS PostCount, SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.Id, u.DisplayName
ORDER BY PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
