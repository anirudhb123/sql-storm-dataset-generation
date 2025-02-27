SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    C.Text AS CommentText
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Retrieve the latest 10 questions with their comments
