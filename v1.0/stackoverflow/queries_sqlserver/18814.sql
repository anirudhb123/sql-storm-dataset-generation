
SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Posts P
JOIN 
    Comments C ON P.Id = C.PostId
JOIN 
    Users U ON C.UserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.Score,
    C.Text,
    C.CreationDate
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
