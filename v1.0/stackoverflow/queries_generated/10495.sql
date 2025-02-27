-- Performance benchmarking query to analyze Posts and related data
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
    UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '> <')) AS T(TagName) ON T.TagName IS NOT NULL
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    P.Id, U.Reputation, U.DisplayName, T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
