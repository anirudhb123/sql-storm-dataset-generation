WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag 
         JOIN Tags t ON t.TagName = tag) AS Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 MONTH')
),

PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN rp.Score >= 100 THEN 'High'
            WHEN rp.Score >= 50  THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.ScoreCategory,
    u.DisplayName AS OwnerName,
    COALESCE(badgeCount.BadgeCount, 0) AS TotalBadges
FROM 
    PostScores ps
LEFT JOIN 
    Users u ON ps.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) badgeCount ON u.Id = badgeCount.UserId
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC;
