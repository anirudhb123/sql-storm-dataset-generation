
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @rank := IF(@prevOwnerUserId = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @prevOwnerUserId := p.OwnerUserId,
        COALESCE(CAST(NULLIF(SUBSTRING(p.Body, 1, 100), '') AS CHAR), 'No content') AS Snippet
    FROM 
        Posts p,
        (SELECT @rank := 0, @prevOwnerUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
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
        ups.PostCount,
        ups.TotalScore,
        ups.TotalViews,
        @userRank := IF(@prevTotalScore = ups.TotalScore, @userRank, @userRank + 1) AS UserRank,
        @prevTotalScore := ups.TotalScore
    FROM 
        UserPostStats ups,
        (SELECT @userRank := 0, @prevTotalScore := NULL) AS vars
    WHERE 
        ups.PostCount > 0
    ORDER BY 
        ups.TotalScore DESC
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    rp.Title,
    rp.CreationDate,
    rp.Snippet
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.UserRank <= 10 
    AND rp.Rank = 1
ORDER BY 
    tu.TotalScore DESC, 
    rp.CreationDate DESC;
