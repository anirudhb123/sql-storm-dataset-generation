WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN p.Score > 0 THEN 1 END) OVER(PARTITION BY p.OwnerUserId) AS PositiveScoreCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date > u.CreationDate
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
AggregatedLinkTypes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN pl.LinkTypeId = 1 THEN 1 ELSE 0 END) AS LinkedCount,
        SUM(CASE WHEN pl.LinkTypeId = 3 THEN 1 ELSE 0 END) AS DuplicateCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    ub.BadgeCount,
    ub.BadgeNames,
    phs.HistoryCount,
    alt.LinkedCount, 
    alt.DuplicateCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 10 THEN 'High Score'
        ELSE 'Average Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
LEFT JOIN 
    AggregatedLinkTypes alt ON rp.PostId = alt.PostId
WHERE 
    (rp.Rank <= 5 AND ub.BadgeCount > 0)
    OR (rp.CommentCount > 10 AND ub.BadgeCount IS NULL)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
