WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -2, GETDATE()) 
        AND p.Score >= 5
),
UserExperience AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetailWithLinks AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pl.RelatedPostId,
        COUNT(pl.Id) AS LinkCount,
        MAX(pl.CreationDate) AS LatestLinkDate
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.Title
),
CloseReasonExclusion AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN cr.Name IS NOT NULL THEN cr.Name ELSE 'N/A' END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only considering post closure and reopening
    GROUP BY 
        ph.PostId
)

SELECT 
    up.UserId,
    up.Reputation,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViews,
    pl.LinkCount AS RelatedPostLinks,
    pl.LatestLinkDate AS LatestLinkDate,
    COALESCE(cre.CloseReasons, 'No closure or reopening reasons') AS ClosureComments
FROM 
    UserExperience up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId 
LEFT JOIN 
    PostDetailWithLinks pl ON rp.Id = pl.PostId 
LEFT JOIN 
    CloseReasonExclusion cre ON rp.Id = cre.PostId
WHERE 
    up.Reputation >= 1000 
    AND up.BadgeCount > 5
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
