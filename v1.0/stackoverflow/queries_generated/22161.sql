WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, ','::TEXT)::int[]))) AS PostTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 24) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.PostTags,
    ub.BadgeCount AS UserBadgeCount,
    ub.MaxBadgeClass AS UserMaxBadgeClass,
    pui.LastClosedDate,
    pui.LastReopenedDate,
    pui.EditCount,
    CASE 
        WHEN pui.LastClosedDate IS NOT NULL AND pui.LastReopenedDate IS NULL THEN 'Closed'
        WHEN pui.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = ub.UserId)
LEFT JOIN 
    PostHistoryInfo pui ON rp.PostId = pui.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC,
    rp.CreationDate DESC;

