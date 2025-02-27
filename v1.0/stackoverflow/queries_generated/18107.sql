SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerDisplayName, 
    P.Score, 
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  -- Filtering for Questions
GROUP BY 
    P.Id, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;  -- Fetching the latest 10 questions
