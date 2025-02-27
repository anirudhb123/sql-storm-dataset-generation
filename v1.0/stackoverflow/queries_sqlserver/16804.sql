
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.Score AS PostScore,
    COUNT(C.ID) AS CommentCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score
ORDER BY 
    PostDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
