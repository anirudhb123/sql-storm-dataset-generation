
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
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
        @rank := IF(@prevTotalScore = TotalScore, @rank, @rank + 1) AS UserRank,
        @prevTotalScore := TotalScore
    FROM UserPostStats, (SELECT @rank := 0, @prevTotalScore := NULL) AS t
    ORDER BY TotalScore DESC
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
