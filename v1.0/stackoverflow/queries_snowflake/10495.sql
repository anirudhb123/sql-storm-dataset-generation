
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.Reputation AS OwnerReputation,
    U.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(P.Tags, 2, LENGTH(P.Tags) - 2), '> <')) AS T
WHERE 
    P.CreationDate >= DATEADD(year, -1, '2024-10-01')
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.DisplayName, T.VALUE
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
