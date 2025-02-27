WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreatedAt,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
PopularComments AS (
    SELECT 
        c.Id,
        c.PostId,
        c.Text,
        c.CreationDate,
        c.Score,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.Score DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName,
    u.Reputation,
    u.Views AS UserViews,
    u.BadgeCount,
    c.Text AS TopComment,
    c.Score AS CommentScore
FROM 
    RankedPosts p
LEFT JOIN 
    RecentUsers u ON p.Rank = 1
LEFT JOIN 
    PopularComments c ON p.PostId = c.PostId AND c.CommentRank = 1
WHERE 
    (p.Score > 100 OR p.ViewCount > 1000)
    AND (u.Reputation > 50 OR u.BadgeCount > 3)
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;

-- Corner cases to consider:
-- 1. Posts with no comments will show NULL for TopComment.
-- 2. Users with low reputation or no badges will still be included if posts meet criteria.
-- 3. `COALESCE` could be used if you'd like to replace NULLs in results with default values.
