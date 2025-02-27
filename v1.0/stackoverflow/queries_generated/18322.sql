SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 -- Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Retrieve the latest 10 questions with comments
