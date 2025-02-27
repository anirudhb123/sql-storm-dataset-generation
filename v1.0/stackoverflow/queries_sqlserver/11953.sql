
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    U.DisplayName AS AuthorDisplayName,
    U.Reputation AS AuthorReputation
FROM 
    Posts AS P
JOIN 
    Users AS U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments AS C ON P.Id = C.PostId
LEFT JOIN 
    Votes AS V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
