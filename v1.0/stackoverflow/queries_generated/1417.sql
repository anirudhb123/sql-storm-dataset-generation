WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        h.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE 
        h.Name = 'Post Closed'
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
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    cb.CreationDate AS ClosedDate,
    ub.BadgeCount,
    CASE 
        WHEN rp.OwnerPostRank = 1 THEN 'Latest Post of User'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
WHERE 
    rp.CommentCount > 5
    OR cb.CreationDate IS NOT NULL
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
