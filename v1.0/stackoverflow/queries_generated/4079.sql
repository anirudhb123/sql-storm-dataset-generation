WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.AnswerCount, 
        p.CreationDate, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS total_posts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
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
),
PostHistoryCount AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
PostLinksCount AS (
    SELECT 
        pl.PostId, 
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(phc.EditCount, 0)) AS TotalEdits,
    SUM(COALESCE(plc.LinkCount, 0)) AS TotalLinks,
    AVG(rp.Score) AS AvgPostScore,
    MAX(rp.CreationDate) AS LatestPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistoryCount phc ON rp.Id = phc.PostId
LEFT JOIN 
    PostLinksCount plc ON rp.Id = plc.PostId
WHERE 
    u.Reputation > 100 
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate 
HAVING 
    COUNT(DISTINCT rp.Id) > 5
ORDER BY 
    AvgPostScore DESC, TotalPosts DESC
LIMIT 10;
