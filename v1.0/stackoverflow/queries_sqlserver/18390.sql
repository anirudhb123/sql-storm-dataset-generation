
SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerDisplayName,
    PT.Name AS PostTypeName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.Score > 0
GROUP BY 
    P.Title, 
    P.CreationDate, 
    U.DisplayName, 
    PT.Name
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
