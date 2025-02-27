
SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate,
    P.ViewCount,
    COUNT(C.ID) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.ViewCount
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
