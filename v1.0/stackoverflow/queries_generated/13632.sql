-- Performance Benchmarking Query
SELECT 
    P.Id AS PostId, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount, 
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT V.UserId) AS UniqueVoterCount,
    AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS AverageUpVotes,
    AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS AverageDownVotes,
    U.Reputation AS OwnerReputation
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= '2021-01-01' -- Filtering for posts created in 2021 or later
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100; -- Limits the results to the most recent 100 posts
