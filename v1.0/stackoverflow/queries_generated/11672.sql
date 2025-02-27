-- Performance Benchmarking Query
-- This query retrieves the users with the highest reputation and the posts they have created, sorted by post creation date.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation > 0
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC
LIMIT 100; -- Limit to top 100 users for performance benchmarking
