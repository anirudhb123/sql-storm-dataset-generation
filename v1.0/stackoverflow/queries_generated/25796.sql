WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerDisplayName
),
TopUserPosts AS (
    SELECT 
        PostId, 
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rnk <= 3 -- Top 3 recent questions per user
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT bp.PostId) AS TotalPosts,
        SUM(bp.ViewCount) AS TotalViews,
        SUM(bp.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        TopUserPosts bp ON u.Id = bp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgesSummary AS (
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
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalViews,
    us.TotalScore,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStats us
LEFT JOIN 
    BadgesSummary bs ON us.UserId = bs.UserId
ORDER BY 
    us.Reputation DESC
LIMIT 10; -- Get the top 10 users based on reputation
