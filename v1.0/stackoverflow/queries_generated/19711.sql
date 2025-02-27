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
    P.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    P.Score DESC 
LIMIT 10; -- Getting top 10 questions by score
