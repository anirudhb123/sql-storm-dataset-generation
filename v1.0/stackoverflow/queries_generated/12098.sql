-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        COUNT(DISTINCT C.Id) AS CommentCount, 
        SUM(V.VoteTypeId = 2) AS UpVotes, 
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)

SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    CommentCount, 
    UpVotes, 
    DownVotes
FROM 
    TopUsers
WHERE 
    Rank <= 10; -- Adjust as needed for top N users
