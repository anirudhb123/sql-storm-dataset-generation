
SELECT 
    P.Id AS PostId, 
    P.Title, 
    P.Score, 
    U.DisplayName AS OwnerDisplayName, 
    P.CreationDate 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, P.Score, U.DisplayName, P.CreationDate 
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;
