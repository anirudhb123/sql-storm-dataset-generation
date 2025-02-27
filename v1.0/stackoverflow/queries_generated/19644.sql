SELECT 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  -- Fetching only questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10;  -- Limit to most recent 10 questions
