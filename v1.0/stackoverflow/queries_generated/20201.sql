WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Only Gold badges
    GROUP BY 
        b.UserId
),
TopCommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
    HAVING 
        COUNT(c.Id) > 5  -- More than 5 comments
),
DistinctTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT TRIM(UNNEST(string_to_array(p.Tags, '<>')))) AS TagCount
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ub.BadgeCount,
    ub.BadgeNames,
    tc.CommentCount,
    dt.TagCount,
    rcp.LastClosed
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN 
    TopCommentedPosts tc ON rp.PostId = tc.PostId
LEFT JOIN 
    DistinctTagCounts dt ON rp.PostId = dt.PostId
LEFT JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.PostId
WHERE 
    rp.Rank <= 10 -- Only Top 10 posts per Post Type
    AND rp.Score > 0 -- Only positive scored posts
    AND dt.TagCount IS NOT NULL -- Posts with tags
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
This query structure provides an elaborate benchmarking of posts within the specified schema, utilizing CTEs for organization and efficiency. It combines ranking, user badge data, commenting statistics, and recent post history to produce a multifaceted view suitable for performance evaluation.
