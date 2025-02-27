WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Considering only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 5 -- Top 5 posts per user
),
UserScorecards AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(tp.Score) AS TotalScore,
        COUNT(tp.PostId) AS TotalPosts
    FROM 
        Users u
    JOIN 
        TopPosts tp ON u.Id = tp.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    us.DisplayName,
    us.TotalScore,
    us.TotalPosts,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserScorecards us
LEFT JOIN 
    UserBadges ub ON us.UserId = ub.UserId
ORDER BY 
    us.TotalScore DESC, us.TotalPosts DESC
LIMIT 10; -- Top 10 users based on post scores from their best questions
