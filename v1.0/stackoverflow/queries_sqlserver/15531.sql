
SELECT 
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    SUM(C.Score) AS CommentScore
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Title,
    P.CreationDate,
    U.DisplayName,
    P.ViewCount,
    P.Score,
    P.AnswerCount
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
