-- Performance benchmarking SQL query
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    CASE 
        WHEN P.PostTypeId = 1 THEN 'Question'
        WHEN P.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    STDEV(P.SCORE) OVER (PARTITION BY P.PostTypeId) AS ScoreStandardDeviation,
    AVG(P.Score) OVER (PARTITION BY P.PostTypeId) AS AvgScorePerPostType
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
