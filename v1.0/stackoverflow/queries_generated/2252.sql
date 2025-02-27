WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    u.DisplayName,
    ub.BadgeCount,
    CASE 
        WHEN ub.MaxBadgeClass IS NULL THEN 'No Badge'
        ELSE CASE 
            WHEN ub.MaxBadgeClass = 1 THEN 'Gold'
            WHEN ub.MaxBadgeClass = 2 THEN 'Silver'
            WHEN ub.MaxBadgeClass = 3 THEN 'Bronze'
        END
    END AS MaxBadge
FROM 
    RankedPosts rp
INNER JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
