SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 -- Only questions
GROUP BY 
    P.Id, U.DisplayName
ORDER BY 
    P.Score DESC
LIMIT 10;
