
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName, P.ViewCount, P.AnswerCount, P.CommentCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
