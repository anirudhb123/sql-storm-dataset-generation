WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(b.Class, 0) AS UserBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1 -- Gold badges
    WHERE 
        p.PostTypeId = 1 -- Questions only
),

RecentActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    WHERE 
        CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY PostId
),

PostStats AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ra.CommentCount,
        ra.LastCommentDate,
        CASE 
            WHEN ra.CommentCount > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS PostActivity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.Id = ra.PostId
)

SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.LastCommentDate,
    ps.PostActivity,
    ps.UserBadgeClass
FROM 
    PostStats ps
WHERE 
    ps.PostRank = 1
    AND ps.Score > 10
    AND (ps.CommentCount IS NULL OR ps.CommentCount < 5)
ORDER BY 
    ps.CreationDate DESC
LIMIT 50

UNION ALL

SELECT 
    'No Recent Activity Posts' AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    COUNT(*) AS CommentCount,
    NULL AS LastCommentDate,
    'Inactive' AS PostActivity,
    NULL AS UserBadgeClass
FROM 
    Posts
WHERE 
    Id NOT IN (SELECT PostId FROM RecentActivity) AND PostTypeId = 1
HAVING 
    COUNT(*) > 0;
