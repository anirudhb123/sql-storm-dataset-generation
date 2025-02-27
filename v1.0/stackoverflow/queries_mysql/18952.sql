
SELECT U.DisplayName, P.Title, P.CreationDate, P.ViewCount
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
GROUP BY U.DisplayName, P.Title, P.CreationDate, P.ViewCount
ORDER BY P.ViewCount DESC
LIMIT 10;
