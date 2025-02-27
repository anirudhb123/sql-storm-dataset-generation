
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalVotes,
    u.TotalViews,
    u.TotalScore,
    @row_num := @row_num + 1 AS UserRank
FROM UserPostStats u
JOIN (SELECT @row_num := 0) AS rn
ORDER BY u.TotalScore DESC;
