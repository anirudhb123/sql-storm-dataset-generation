-- Performance benchmarking query to analyze post metrics
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2021-01-01' -- Adjust start date for benchmarking period
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, U.DisplayName
ORDER BY 
    P.Score DESC, P.ViewCount DESC; -- Order by score and view count for performance insights
