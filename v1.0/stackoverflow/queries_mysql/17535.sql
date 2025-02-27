
SELECT 
    P.Id AS PostId, 
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
    P.ViewCount > 100
GROUP BY 
    P.Id, 
    P.Title, 
    P.CreationDate, 
    U.DisplayName, 
    PT.Name
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
