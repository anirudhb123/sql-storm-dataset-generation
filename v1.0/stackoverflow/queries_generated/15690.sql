SELECT 
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
    P.PostTypeId = 1  -- Filter for Questions
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;  -- Limit results to the most recent 10 questions
