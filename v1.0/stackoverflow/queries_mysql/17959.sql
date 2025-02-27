
SELECT U.DisplayName, P.Title, P.CreationDate, P.Score
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
WHERE P.PostTypeId = 1
GROUP BY U.DisplayName, P.Title, P.CreationDate, P.Score
ORDER BY P.Score DESC
LIMIT 10;
