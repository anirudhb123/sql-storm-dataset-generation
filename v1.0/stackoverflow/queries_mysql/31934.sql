
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.ViewCount > 100
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        GROUP_CONCAT(Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
FilteredUserBadges AS (
    SELECT 
        ub.UserId,
        ub.TotalBadges,
        ub.BadgeNames
    FROM 
        UserBadges ub
    WHERE 
        ub.TotalBadges > 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    uub.TotalBadges,
    uub.BadgeNames,
    phs.HistoryCount,
    phs.LastEditDate,
    phs.EditTypes 
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    FilteredUserBadges uub ON p.OwnerUserId = uub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
