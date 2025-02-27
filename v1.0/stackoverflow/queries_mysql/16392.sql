
SELECT 
    P.Title, 
    U.DisplayName AS OwnerDisplayName, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Title, 
    U.DisplayName, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
