WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pViewScores.ViewCount,
        pScoreScores.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY pCreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(ViewCount) AS ViewCount
        FROM 
            Posts
        GROUP BY 
            PostId
    ) pViewScores ON p.Id = pViewScores.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(Score) AS Score
        FROM 
            Posts
        GROUP BY 
            PostId
    ) pScoreScores ON p.Id = pScoreScores.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.RowNum = 1 AND ub.BadgeCount > 5
)
SELECT 
    pp.PostId,
    pp.Title,
    COALESCE(pp.ViewCount, 0) AS TotalViews,
    COALESCE(pp.Score, 0) AS TotalScore,
    CASE 
        WHEN pp.BadgeCount IS NULL THEN 'No Badges'
        ELSE CONCAT(pp.BadgeCount, ' Badges')
    END AS BadgeStatus
FROM 
    PopularPosts pp
WHERE 
    pp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
