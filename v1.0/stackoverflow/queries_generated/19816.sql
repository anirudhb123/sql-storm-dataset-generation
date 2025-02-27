SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.ViewCount,
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Only select questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Limit to the most recent 10 questions
