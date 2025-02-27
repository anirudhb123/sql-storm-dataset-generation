
SELECT U.DisplayName, P.Title, P.CreationDate, P.ViewCount
FROM Posts P
INNER JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
GROUP BY U.DisplayName, P.Title, P.CreationDate, P.ViewCount
ORDER BY P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
