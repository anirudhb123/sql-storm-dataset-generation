
SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS Author, 
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
    P.CreationDate, 
    U.DisplayName, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount 
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;
