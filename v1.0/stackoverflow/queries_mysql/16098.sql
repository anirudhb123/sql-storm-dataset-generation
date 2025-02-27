
SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount
FROM 
    Users AS U
JOIN 
    Posts AS P ON U.Id = P.OwnerUserId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount
ORDER BY 
    P.Score DESC
LIMIT 10;
