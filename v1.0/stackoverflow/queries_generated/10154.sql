-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves posts along with their associated user information, 
-- comment counts, and badge counts to evaluate the performance on joins and aggregations.
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COALESCE(CA.CommentCount, 0) AS TotalCommentCount,
    COALESCE(B.BadgeCount, 0) AS TotalBadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) CA ON P.Id = CA.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(Id) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
ORDER BY 
    P.ViewCount DESC  -- Order by the number of views
LIMIT 100;  -- Limit the result set to top 100 posts
