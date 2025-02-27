WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*)
             FROM Comments c
             WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT bp.PostId) AS BestPostsCount,
        SUM(bp.Score) AS TotalScore,
        AVG(bp.ViewCount) AS AvgViewCount,
        MAX(bp.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId AND bp.Rank <= 5
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ad.DisplayName,
    ad.BestPostsCount,
    ad.TotalScore,
    ad.AvgViewCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    ub.BadgeCount,
    CASE 
        WHEN ad.LastPostDate IS NULL THEN 'No Posts'
        WHEN ad.LastPostDate < NOW() - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS UserActivityStatus
FROM 
    AggregatedData ad
LEFT JOIN 
    UserBadges ub ON ad.UserId = ub.UserId
WHERE 
    ad.BestPostsCount > 0
ORDER BY 
    ad.TotalScore DESC, ad.DisplayName ASC;
