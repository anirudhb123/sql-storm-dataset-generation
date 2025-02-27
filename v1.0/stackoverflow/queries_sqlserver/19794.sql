
SELECT 
    P.Id AS PostId, 
    P.Title, 
    U.DisplayName AS OwnerDisplayName, 
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
    P.Id, 
    P.Title, 
    U.DisplayName, 
    P.CreationDate, 
    P.ViewCount, 
    P.Score 
ORDER BY 
    P.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
