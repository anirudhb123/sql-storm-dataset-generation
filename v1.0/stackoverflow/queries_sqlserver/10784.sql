
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    T.TagName,
    COUNT(C.Id) AS CommentsCount,
    COUNT(V.Id) AS VotesCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
CROSS APPLY 
    (SELECT value AS TagName FROM STRING_SPLIT(P.Tags, '><')) AS T
WHERE 
    P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days'
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation, T.TagName
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
