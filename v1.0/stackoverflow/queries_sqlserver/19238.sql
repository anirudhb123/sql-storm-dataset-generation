
SELECT 
    P.Id AS PostID,
    P.Title,
    U.DisplayName AS Owner,
    P.Score,
    P.ViewCount,
    P.CreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.Score, P.ViewCount, P.CreationDate
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
