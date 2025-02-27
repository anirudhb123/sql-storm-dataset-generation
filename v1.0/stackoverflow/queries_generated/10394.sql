WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.VoteCount IS NULL THEN 0 ELSE p.VoteCount END) AS VoteCount,
        SUM(b.Id IS NOT NULL) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        VoteCount,
        BadgeCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserStats
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    TotalScore, 
    VoteCount, 
    BadgeCount,
    ScoreRank, 
    PostRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR PostRank <= 10
ORDER BY 
    ScoreRank, PostRank;
