
SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
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
    C.CreationDate DESC
LIMIT 10;
