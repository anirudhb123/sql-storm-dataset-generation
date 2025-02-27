
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    P.CreationDate,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    Tags T ON T.ExcerptPostId = P.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id,
    P.Title,
    U.DisplayName,
    P.Score,
    P.ViewCount,
    P.CreationDate,
    T.TagName
ORDER BY 
    P.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
