WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::jsonb ->> 'CloseReasonId'::text = cr.Id::text
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Consider closed and reopened posts
),
OpenPosts AS (
    SELECT 
        rp.PostId,
        COUNT(cp.PostId) AS ClosureCount,
        AVG(rp.Score) AS AvgScore,
        STRING_AGG(DISTINCT rp.Tags::text, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    GROUP BY 
        rp.PostId
    HAVING 
        COUNT(cp.PostId) = 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
)
SELECT 
    op.PostId,
    op.AvgScore,
    op.ClosureCount,
    op.Tags,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Gold Badges'
        ELSE 'Gold Badge Holder'
    END AS BadgeStatus
FROM 
    OpenPosts op
LEFT JOIN 
    UserBadges ub ON op.OwnerDisplayName = ub.UserId::text
WHERE 
    op.AvgScore > 10
ORDER BY 
    op.AvgScore DESC, 
    op.ClosureCount DESC
LIMIT 50;

-- Additional check for NULLs and unusual cases
SELECT 
    op.PostId,
    CASE 
        WHEN op.AvgScore IS NULL THEN 'No score recorded'
        ELSE TO_CHAR(op.AvgScore, 'FM9999')
    END AS FormattedScore,
    COALESCE(op.Tags, 'No tags available') AS DisplayTags
FROM 
    OpenPosts op
WHERE 
    (op.AvgScore IS NULL OR op.ClosureCount IS NULL)
ORDER BY 
    op.PostId;
