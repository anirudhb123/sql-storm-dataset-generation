
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalScore,
        TotalViews,
        VoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewsRank
    FROM UserStats
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    TotalScore,
    TotalViews,
    VoteCount,
    ReputationRank,
    ScoreRank,
    ViewsRank
FROM TopUsers
WHERE ReputationRank <= 10 OR ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY Reputation DESC;
