SELECT 
    P.Id AS PostId, 
    P.Title, 
    U.DisplayName AS OwnerName, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  -- Filtering for questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10;  -- Limiting results to the latest 10 questions
