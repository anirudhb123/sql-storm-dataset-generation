
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    C.CommentCount,
    A.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) A ON P.Id = A.ParentId
WHERE 
    P.PostTypeId = 1
GROUP BY 
    P.Id, 
    P.Title, 
    P.CreationDate, 
    U.DisplayName, 
    P.Score, 
    P.ViewCount, 
    C.CommentCount, 
    A.AnswerCount
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
