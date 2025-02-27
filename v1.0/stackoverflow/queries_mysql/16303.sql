
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    C.CommentCount,
    GROUP_CONCAT(T.TagName SEPARATOR ', ') AS TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT PostId, TagName FROM Tags) T ON P.Id = T.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.CreationDate, P.ViewCount, P.Score, C.CommentCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
