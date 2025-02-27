WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostTypesCTE AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Id, pt.Name
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
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.OwnerDisplayName,
    r.CommentCount,
    pt.PostTypeName,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
FROM 
    RankedPosts r
JOIN 
    PostTypesCTE pt ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.PostTypeId)
LEFT JOIN 
    UserBadges ub ON r.OwnerUserId = ub.UserId
WHERE 
    r.RN = 1
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 100
UNION ALL
SELECT 
    NULL AS PostId,
    NULL AS Title,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS OwnerDisplayName,
    NULL AS CommentCount,
    NULL AS PostTypeName,
    COUNT(*) AS UserBadgeCount
FROM 
    Badges
WHERE 
    CreatedDate >= NOW() - INTERVAL '1 month'
GROUP BY 
    UserId
ORDER BY 
    UserBadgeCount DESC
LIMIT 1;
