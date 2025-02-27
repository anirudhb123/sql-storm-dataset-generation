SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Comment) AS CommentCount,
    COUNT(V.Id) AS VoteCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01' -- Example filter for posts created in 2023
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC;
