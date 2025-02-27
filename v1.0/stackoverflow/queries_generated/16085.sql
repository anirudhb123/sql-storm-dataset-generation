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
    P.PostTypeId = 1  -- Questions only
ORDER BY 
    C.CreationDate DESC
LIMIT 10;
