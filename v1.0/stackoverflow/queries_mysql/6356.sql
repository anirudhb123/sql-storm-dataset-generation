
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Id, 0)) AS TotalComments,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedStats AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalScore, 
        TotalComments, 
        BadgeCount,
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM 
        UserStats, (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY 
        TotalScore DESC, Reputation DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        TotalComments,
        BadgeCount
    FROM 
        RankedStats
    WHERE 
        ScoreRank <= 10
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalComments,
    tu.BadgeCount,
    GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS PostTypeNames,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostLinks
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.TotalScore, tu.TotalComments, tu.BadgeCount
ORDER BY 
    tu.TotalScore DESC;
