-- Performance Benchmarking Query
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.LastActivityDate,
    P.Score,
    P.ViewCount,
    COUNT(C.CommentId) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryCreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId 
WHERE 
    P.CreationDate >= '2023-01-01' -- Filter by posts created in 2023
GROUP BY 
    P.Id, U.DisplayName, PH.PostHistoryTypeId
ORDER BY 
    P.LastActivityDate DESC
LIMIT 100; -- Limit to the latest 100 posts
