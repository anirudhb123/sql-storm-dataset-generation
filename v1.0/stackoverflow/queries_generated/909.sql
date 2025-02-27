WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rc.CommentCount,
    rc.LastCommentDate,
    us.Reputation,
    us.BadgeCount,
    CASE 
        WHEN us.BadgeCount > 0 THEN 'Badge Holder'
        ELSE 'No Badge'
    END AS UserBadgeStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rc.LastCommentDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additionally to benchmark performance, create a UNION of tags with high counts and post history types
SELECT 
    t.TagName AS EntityName,
    t.Count AS EntityCount
FROM 
    Tags t
WHERE 
    t.Count > 100
UNION ALL
SELECT 
    pht.Name AS EntityName,
    COUNT(ph.Id) AS EntityCount
FROM 
    PostHistoryTypes pht
LEFT JOIN 
    PostHistory ph ON pht.Id = ph.PostHistoryTypeId
GROUP BY 
    pht.Name
HAVING 
    COUNT(ph.Id) > 50
ORDER BY 
    EntityCount DESC;
