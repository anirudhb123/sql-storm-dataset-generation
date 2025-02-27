
SELECT 
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    PT.Name AS PostTypeName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.Score > 10
GROUP BY 
    P.Title,
    U.DisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    PT.Name
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
