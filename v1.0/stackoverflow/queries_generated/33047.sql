WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tag edits
        AND ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    COALESCE(re.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(re.Comment, 'N/A') AS EditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
WHERE 
    rp.rn = 1 -- Only the latest post for each user
ORDER BY 
    rp.ViewCount DESC,
    rp.Score DESC
LIMIT 100;

-- Additional benchmarking to check performance:
EXPLAIN ANALYZE
WITH RankedPosts AS (
    SELECT ...
    -- Same CTEs as above
)
SELECT ...
-- Same final query as above
