-- Performance Benchmarking SQL Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    UpVotes,
    DownVotes
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10; -- Top 10 users by score

