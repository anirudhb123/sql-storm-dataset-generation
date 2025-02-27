-- Performance benchmarking SQL query
-- This query retrieves various metrics about posts, comments, and user interactions
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS TotalComments,
    COUNT(V.Id) AS TotalVotes,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year' -- filtering for posts created in the last year
GROUP BY 
    P.Id, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC; -- ordering the results by the creation date of the posts
