-- Performance Benchmarking SQL Query Example
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    P.ViewCount,
    P.Score,
    P.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2020-01-01'  -- Filtering posts created in 2020 and later
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;  -- Limiting results to the most recent 100 posts
