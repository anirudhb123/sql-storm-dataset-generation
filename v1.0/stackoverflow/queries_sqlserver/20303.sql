
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.ParentId, 0) AS ParentPostId,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 DAY'
),

AggregatedUserData AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

FilteredComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.CreationDate,
        CASE 
            WHEN c.UserId IS NULL THEN 'Anonymous' 
            ELSE (SELECT DisplayName FROM Users u WHERE u.Id = c.UserId)
        END AS UserName
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '7 DAY')
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    au.UserId,
    au.AvgReputation,
    au.TotalBadges,
    au.TotalPosts,
    fc.CommentId,
    fc.Text AS CommentText,
    fc.CreationDate AS CommentCreationDate,
    fc.UserName
FROM 
    RecentPosts rp
LEFT JOIN 
    AggregatedUserData au ON rp.ParentPostId = au.UserId
LEFT JOIN 
    FilteredComments fc ON rp.PostId = fc.PostId
WHERE 
    (rp.Score > 10 OR rp.ViewCount > 100) AND 
    (fc.CreationDate IS NULL OR fc.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 WEEK'))
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC, 
    au.AvgReputation DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
