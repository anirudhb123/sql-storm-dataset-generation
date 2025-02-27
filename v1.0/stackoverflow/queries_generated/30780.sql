WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.OwnerUserId, 
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start from top-level questions
    UNION ALL
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.OwnerUserId, 
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
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
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        ub.BadgeCount,
        CASE 
            WHEN rp.Score < 0 THEN 'Low'
            WHEN rp.Score BETWEEN 0 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS ScoreCategory
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
),
FilteredPosts AS (
    SELECT 
        pa.Title,
        pa.OwnerDisplayName,
        pa.ViewCount,
        pa.BadgeCount,
        pa.ScoreCategory
    FROM 
        PostAnalytics pa
    WHERE 
        pa.ViewCount > 10 AND 
        pa.BadgeCount > 0 AND 
        pa.ScoreCategory = 'High'
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.ViewCount,
    fp.BadgeCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC
LIMIT 10;
