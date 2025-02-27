-- Performance Benchmark Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(B.Class) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalBounties,
    TotalBadges
FROM UserStatistics 
ORDER BY TotalPosts DESC 
LIMIT 10;
