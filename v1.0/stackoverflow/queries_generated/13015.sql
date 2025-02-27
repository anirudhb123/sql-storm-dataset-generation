-- Performance Benchmarking Query for the StackOverflow Schema

-- This query evaluates the overall performance by fetching statistics about Posts, Users, Votes, and their relationships.
SELECT 
    P.Id AS PostID,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    P.ViewCount,
    P.Score,
    COALESCE(COUNT(V.id), 0) AS TotalVotes,
    COALESCE((SELECT COUNT(C.id) FROM Comments C WHERE C.PostId = P.Id), 0) AS TotalComments,
    COALESCE((SELECT COUNT(B.id) FROM Badges B WHERE B.UserId = U.Id), 0) AS TotalBadges
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Change interval as needed
GROUP BY 
    P.Id, U.Id
ORDER BY 
    P.CreationDate DESC;
