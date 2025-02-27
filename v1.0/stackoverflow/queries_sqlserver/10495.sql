
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
OUTER APPLY 
    (SELECT value AS TagName 
     FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '> <') 
     WHERE value IS NOT NULL) T
WHERE 
    P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01')
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.DisplayName, T.TagName
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;
