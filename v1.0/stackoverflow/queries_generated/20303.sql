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
        p.CreationDate > NOW() - INTERVAL '30 days'
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
        c.CreationDate >= (NOW() - INTERVAL '7 days')
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
    (fc.CreationDate IS NULL OR fc.CreationDate >= (NOW() - INTERVAL '1 week'))
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC, 
    au.AvgReputation DESC
LIMIT 100;

-- This query does the following:
-- 1. Defines a CTE (Common Table Expression) for recent posts made in the last 30 days.
-- 2. Aggregates user data including average reputation and total badges.
-- 3. Filters comments made in the last 7 days.
-- 4. Joins all the data to produce a comprehensive view of posts, taking into account their scores and view counts.
-- 5. Uses COALESCE and a correlated subquery to handle NULL values in user names for comments.
-- 6. Applies complex predicates to filter and order the data for benchmarking.
-- 7. Limits the final output to 100 entries maximizing the relevant data display.
