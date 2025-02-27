SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName, 
    P.Score, 
    P.ViewCount 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  -- This filters for questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
