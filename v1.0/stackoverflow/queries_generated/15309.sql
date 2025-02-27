SELECT 
    P.Title,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    C.CommentCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            STRING_AGG(T.TagName, ', ') AS TagName
        FROM 
            Tags T
        WHERE 
            P.Tags LIKE '%' || T.TagName || '%'
    ) T ON TRUE
WHERE 
    P.PostTypeId = 1
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
