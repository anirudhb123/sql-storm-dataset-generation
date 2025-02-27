SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS Owner,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Only questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10; -- Fetch the latest 10 questions
