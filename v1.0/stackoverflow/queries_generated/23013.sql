WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        DATEDIFF(SECOND, p.CreationDate, p.LastActivityDate) AS ActiveDuration,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankInType
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
        AND p.Score IS NOT NULL
),
BadgeStats AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        (CASE WHEN bs.BadgeCount IS NULL THEN 0 ELSE bs.BadgeCount END) AS TotalBadges,
        (CASE WHEN bs.BadgeCount IS NULL OR bs.GoldBadges IS NULL THEN 0 ELSE bs.GoldBadges END) AS GoldBadges,
        (CASE WHEN bs.BadgeCount IS NULL OR bs.SilverBadges IS NULL THEN 0 ELSE bs.SilverBadges END) AS SilverBadges,
        (CASE WHEN bs.BadgeCount IS NULL OR bs.BronzeBadges IS NULL THEN 0 ELSE bs.BronzeBadges END) AS BronzeBadges,
        rp.ActiveDuration
    FROM 
        RankedPosts rp
    LEFT JOIN 
        BadgeStats bs ON rp.OwnerUserId = bs.UserId
    WHERE 
        rp.RankInType = 1
),
AggregatedResults AS (
    SELECT 
        TotalBadges,
        AVG(ActiveDuration) AS AvgActiveDuration,
        SUM(GoldBadges) AS TotalGoldBadges,
        SUM(SilverBadges) AS TotalSilverBadges,
        SUM(BronzeBadges) AS TotalBronzeBadges
    FROM 
        PostWithBadges
    GROUP BY 
        TotalBadges
)
SELECT 
    ar.TotalBadges,
    ar.AvgActiveDuration,
    ar.TotalGoldBadges,
    ar.TotalSilverBadges,
    ar.TotalBronzeBadges,
    COUNT(DISTINCT p.Id) AS PostCount,
    STRING_AGG(CONVERT(VARCHAR, p.Id), ', ') AS PostIds,
    MAX(CASE WHEN p.LastEditDate IS NULL THEN 'Not Edited' ELSE 'Edited' END) AS EditStatus
FROM 
    PostWithBadges p
JOIN 
    AggregatedResults ar ON p.TotalBadges = ar.TotalBadges
GROUP BY 
    ar.TotalBadges, ar.AvgActiveDuration, ar.TotalGoldBadges, ar.TotalSilverBadges, ar.TotalBronzeBadges
ORDER BY 
    ar.TotalBadges DESC
OPTION (RECOMPILE);

