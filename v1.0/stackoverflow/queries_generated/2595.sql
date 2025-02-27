WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), CommentStatistics AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Comments c
    GROUP BY 
        c.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.AvgViewCount,
    us.TotalScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN cs.TotalComments IS NULL THEN 0
        ELSE cs.TotalComments
    END AS TotalComments,
    cs.CommentRank
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    CommentStatistics cs ON us.UserId = cs.UserId
WHERE 
    us.TotalScore > 100 
    AND us.GoldBadges > 0
ORDER BY 
    us.TotalScore DESC, 
    rp.CommentCount DESC
LIMIT 100;
