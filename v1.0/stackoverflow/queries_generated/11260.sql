-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves statistics about posts, their comments, and associated users to analyze performance metrics.

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    COUNT(C.Id) AS CommentCount,
    U.Reputation AS OwnerReputation,
    U.CreationDate AS UserCreationDate,
    U.LastAccessDate,
    U.Views AS UserViews,
    U.UpVotes,
    U.DownVotes,
    COALESCE(AVG(V.BountyAmount), 0) AS AvgBountyAmount
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Consider only BountyStart and BountyClose votes
WHERE 
    P.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year posts
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.CreationDate, U.LastAccessDate, U.Views, U.UpVotes, U.DownVotes
ORDER BY 
    P.CreationDate DESC;
