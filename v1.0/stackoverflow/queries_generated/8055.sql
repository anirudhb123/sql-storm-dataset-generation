WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 
PostHistoryAggregated AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId
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
    pha.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
