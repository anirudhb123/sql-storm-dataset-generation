-- Performance Benchmarking Query

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        TotalScore, 
        TotalUpVotes, 
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM UserPostStats
)

SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    TotalComments, 
    TotalScore, 
    TotalUpVotes, 
    TotalDownVotes
FROM TopUsers
WHERE UserRank <= 10;
