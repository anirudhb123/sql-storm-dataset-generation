WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.PostRank <= 5
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
FROM FilteredPosts fp
LEFT JOIN UserBadgeCounts ub ON ub.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = fp.PostId
)
WHERE fp.ViewCount > 100
ORDER BY fp.Score DESC, fp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Badges' AS Title,
    NULL AS ViewCount,
    SUM(bc.BadgeCount) AS Score,
    NULL AS OwnerDisplayName,
    COUNT(b.Id) AS TotalBadges
FROM Badges b
HAVING COUNT(b.Id) > 10;
