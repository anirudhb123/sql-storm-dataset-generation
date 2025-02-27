WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.Views) AS TotalViews,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalScore,
    us.TotalViews,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC, rp.Score DESC;
