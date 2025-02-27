
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
        AND p.Score IS NOT NULL
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        STRING_AGG(c.Text, ' | ') AS CommentTexts,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= DATEADD(month, -6, '2024-10-01 12:34:56')
    GROUP BY 
        c.PostId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    rc.CommentTexts,
    rc.CommentCount,
    pqa.LastClosedDate,
    pqa.HistoryCount,
    CASE 
        WHEN pqa.LastClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentComments rc ON r.PostId = rc.PostId
LEFT JOIN 
    PostHistoryAggregates pqa ON r.PostId = pqa.PostId
WHERE 
    r.PostRank = 1
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
