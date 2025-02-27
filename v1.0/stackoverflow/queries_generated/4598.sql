WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        STRING_AGG(pl.RelatedPostId::TEXT, ', ') AS RelatedPostIds,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.AvgBounty,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pls.RelatedPostIds,
    pls.LinkCount
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostLinksSummary pls ON rp.Id = pls.PostId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC NULLS LAST, 
    ua.GoldBadges DESC, 
    rp.Score DESC;
