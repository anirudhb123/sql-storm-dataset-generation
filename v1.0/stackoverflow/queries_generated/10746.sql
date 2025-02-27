-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the total number of posts, average views, and average score
-- grouped by post type, also retrieving the top user by reputation for each post type.

WITH UserPostStats AS (
    SELECT 
        P.PostTypeId,
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AverageViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY P.PostTypeId, U.Id
),
RankedUsers AS (
    SELECT 
        PostTypeId,
        UserId,
        Reputation,
        TotalPosts,
        AverageViews,
        AverageScore,
        ROW_NUMBER() OVER (PARTITION BY PostTypeId ORDER BY Reputation DESC) AS UserRank
    FROM UserPostStats
)

SELECT 
    PT.Name AS PostType,
    UPS.TotalPosts,
    UPS.AverageViews,
    UPS.AverageScore,
    U.DisplayName AS TopUser,
    U.Reputation
FROM RankedUsers UPS
JOIN PostTypes PT ON UPS.PostTypeId = PT.Id
JOIN Users U ON UPS.UserId = U.Id
WHERE UPS.UserRank = 1
ORDER BY PT.Id;
