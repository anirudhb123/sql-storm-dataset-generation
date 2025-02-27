
SELECT U.DisplayName, P.Title, P.CreationDate
FROM Users AS U
JOIN Posts AS P ON U.Id = P.OwnerUserId
WHERE P.PostTypeId = 1  
GROUP BY U.DisplayName, P.Title, P.CreationDate
ORDER BY P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
