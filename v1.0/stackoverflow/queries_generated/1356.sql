WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
HighScorers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore,
        us.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC, us.BadgeCount DESC) AS ScoreRank
    FROM 
        UserStats us
    WHERE 
        us.BadgeCount > 5
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    us.DisplayName AS OwnerDisplayName,
    us.TotalScore AS OwnerTotalScore,
    us.BadgeCount AS OwnerBadgeCount,
    hs.ScoreRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON us.UserId = u.Id
LEFT JOIN 
    HighScorers hs ON us.UserId = hs.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
