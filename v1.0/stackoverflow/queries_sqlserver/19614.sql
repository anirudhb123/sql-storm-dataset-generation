
SELECT U.DisplayName, P.Title, P.CreationDate, P.Score
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1 
ORDER BY P.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
