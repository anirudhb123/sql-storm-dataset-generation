
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AveragePostScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.AveragePostScore,
        @rank := IF(@prev_reputation = u.Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := u.Reputation
    FROM
        UserPostStats ups
    JOIN
        Users u ON ups.UserId = u.Id,
        (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY
        u.Reputation DESC
)

SELECT
    UserId,
    DisplayName,
    TotalPosts,
    AveragePostScore
FROM
    TopUsers
WHERE
    ReputationRank <= 10
ORDER BY
    ReputationRank;
