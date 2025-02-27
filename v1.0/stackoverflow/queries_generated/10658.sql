-- Performance Benchmarking SQL Query

-- This query aims to measure the performance of retrieving user reputation, post titles, and related vote counts.
-- It joins Users, Posts, and Votes while filtering for active users with a minimum reputation.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate AS PostCreationDate,
    COUNT(V.Id) AS VoteCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation >= 100 -- Filtering for users with reputation of at least 100 to focus on active contributors
GROUP BY 
    U.Id, P.Id
ORDER BY 
    U.Reputation DESC, VoteCount DESC;

-- Note: Adjust indexes on the Users, Posts, and Votes tables as necessary for optimal performance.
