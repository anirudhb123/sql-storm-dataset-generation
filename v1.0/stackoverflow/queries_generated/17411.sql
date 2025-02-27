SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Select only questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Get the latest 10 questions
