
SELECT 
    P.Title, 
    U.DisplayName AS Owner, 
    P.CreationDate, 
    P.ViewCount, 
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Title, 
    U.DisplayName, 
    P.CreationDate, 
    P.ViewCount, 
    P.Score
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
