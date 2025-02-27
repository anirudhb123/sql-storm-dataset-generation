
SELECT 
    P.Title,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.ViewCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Title, P.Score, U.DisplayName, P.CreationDate, P.ViewCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
