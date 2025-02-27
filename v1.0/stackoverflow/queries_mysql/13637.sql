
SELECT AVG(u.Reputation) AS AverageReputation
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1
GROUP BY u.Reputation, u.Id, p.OwnerUserId, p.PostTypeId;
