SELECT 
    P.Title, 
    U.DisplayName AS Owner, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Filter for questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Get the latest 10 questions
