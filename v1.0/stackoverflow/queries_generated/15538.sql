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
    P.PostTypeId = 1 -- 1 indicates Questions
ORDER BY 
    P.Score DESC
LIMIT 10;
