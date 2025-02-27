SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS Author,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  -- Filter for Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 10;  -- Return the 10 most recent questions
