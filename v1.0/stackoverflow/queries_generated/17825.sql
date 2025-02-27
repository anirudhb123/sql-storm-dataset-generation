SELECT U.DisplayName, COUNT(P.Id) AS PostCount, SUM(V.CreationDate IS NOT NULL) AS VoteCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId
GROUP BY U.DisplayName
HAVING COUNT(P.Id) > 0
ORDER BY PostCount DESC;
