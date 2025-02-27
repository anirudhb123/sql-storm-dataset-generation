
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.ViewCount,
    P.Score,
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
    P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount, P.Score, T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
