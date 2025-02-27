-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the top 10 users with the highest reputation,
-- along with their total number of posts and total votes they received.

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,   -- Counting UpVotes 
        SUM(V.VoteTypeId = 3) AS TotalDownVotes   -- Counting DownVotes 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    TotalUpVotes,
    TotalDownVotes
FROM 
    UserStats
ORDER BY 
    Reputation DESC
LIMIT 10;

-- Here we are aggregating data to evaluate user engagement and post performance.
-- You can also adjust the query for different benchmarking purposes.
