-- Performance benchmarking query for Stack Overflow schema
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CM.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    P.Score,
    P.ViewCount,
    B.Name AS BadgeName,
    COUNT(DISTINCT PH.Id) AS EditHistoryCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1 -- Only Questions
    AND P.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    P.Id, U.DisplayName, B.Name
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 100;
