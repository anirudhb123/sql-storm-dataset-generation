
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    C.Text AS CommentText,
    C.CreationDate AS CommentDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, C.Text, C.CreationDate
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
