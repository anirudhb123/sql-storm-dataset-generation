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
    P.PostTypeId = 1 -- Assuming we want to focus on questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Display the most recent 10 comments on questions
