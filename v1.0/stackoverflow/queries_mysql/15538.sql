
SELECT 
    P.Title, 
    U.DisplayName AS OwnerDisplayName, 
    P.CreationDate, 
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
    P.Score 
ORDER BY 
    P.Score DESC
LIMIT 10;
