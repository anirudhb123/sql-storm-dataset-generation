SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    P.CreationDate,
    U.DisplayName AS Author,
    COUNT(C.CommentId) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    P.Id, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
