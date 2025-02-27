-- Performance benchmarking query to analyze user activity and post engagement
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(COALESCE(P.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalPostScore,
    TotalUpvotes,
    TotalDownvotes,
    (TotalUpvotes - TotalDownvotes) AS NetVotes
FROM UserPostStats
ORDER BY NetVotes DESC
LIMIT 10;
