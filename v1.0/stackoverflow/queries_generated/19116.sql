SELECT u.DisplayName, COUNT(p.Id) AS PostCount, SUM(v.VoteTypeId = 2) AS Upvotes, SUM(v.VoteTypeId = 3) AS Downvotes
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
ORDER BY PostCount DESC;
