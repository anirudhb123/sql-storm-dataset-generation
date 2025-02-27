-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the most active users based on their reputation and number of posts, along with their badges earned.

WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserPostCounts
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    BadgeCount,
    Rank
FROM 
    ActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
