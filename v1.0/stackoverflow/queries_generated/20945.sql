WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), PostHistoryCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory
    WHERE 
        CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        PostId
), FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ph.HistoryCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryCounts ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
        AND (p.ViewCount IS NOT NULL OR p.CommentCount > 0)
), RankedPosts AS (
    SELECT 
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.HistoryCount,
        fp.PostType,
        fp.CommentCount,
        RANK() OVER (PARTITION BY fp.PostType ORDER BY fp.ViewCount DESC) AS Rank
    FROM 
        FilteredPosts fp
)
SELECT
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.HistoryCount,
    rp.CommentCount
FROM 
    UserPosts up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    up.TotalViews DESC, up.PostCount DESC;

-- This query combines user participation with posts while considering post history and performance benchmarks.
-- It ranks posts per type, filters them based on recent performance and user engagement metrics.
