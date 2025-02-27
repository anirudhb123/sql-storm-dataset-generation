WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.BadgeCount) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        TotalPosts,
        TotalComments,
        TotalBadges,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserScores
)

SELECT 
    tu.DisplayName,
    tu.TotalScore,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Tags
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.TotalScore DESC, rp.Score DESC;
