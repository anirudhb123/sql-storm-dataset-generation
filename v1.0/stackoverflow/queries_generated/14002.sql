-- Performance Benchmarking Query for Stack Overflow Schema

-- This query benchmarks the performance of retrieving user information,
-- along with their posts, including their votes, comments, and badges.

WITH UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000  -- Example filter for more active users
    GROUP BY 
        U.Id, P.Id
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    COUNT(DISTINCT PostId) AS TotalPosts,
    SUM(PostScore) AS TotalPostScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes,
    SUM(BadgeCount) AS TotalBadges
FROM 
    UserPostDetails
GROUP BY 
    UserId, DisplayName, Reputation
ORDER BY 
    TotalPosts DESC, TotalPostScore DESC
LIMIT 100; -- Limit results for your benchmarking
