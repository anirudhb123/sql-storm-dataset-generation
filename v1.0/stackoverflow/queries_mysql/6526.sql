
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        RANK() OVER (ORDER BY p.Score DESC) AS GlobalPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score, p.ViewCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId, 
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 6 MONTH)
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ub.BadgeCount,
    ub.BadgeNames,
    phs.HistoryCount
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.GlobalPostRank <= 10
ORDER BY 
    rp.GlobalPostRank;
