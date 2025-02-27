SELECT 
    P.Id AS PostId, 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerDisplayName, 
    P.Score, 
    P.ViewCount 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Limiting the result to the latest 10 questions
