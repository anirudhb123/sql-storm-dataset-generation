
SELECT P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount
ORDER BY P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
