WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS DisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount,
    COALESCE(phc.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN ua.GoldBadges > 0 THEN 'Gold' 
        WHEN ua.SilverBadges > 0 THEN 'Silver' 
        WHEN ua.BronzeBadges > 0 THEN 'Bronze' 
        ELSE 'No Badges' 
    END AS BadgeStatus,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Highly Viewed'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.PostId = ua.UserId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC
LIMIT 10
OFFSET 5;

This query constructs a performance benchmarking scenario that includes:

1. **CTEs:** RankedPosts for recent posts, UserActivity for user metrics, and PostHistoryCounts for tracking edits.
2. **Window Functions:** `ROW_NUMBER()` to rank posts based on their creation dates within their post types.
3. **Aggregations:** Total counts for upvotes, downvotes, comments, and badges.
4. **LEFT JOINs:** To incorporate data from various tables allowing nulls (for users without activity).
5. **COALESCE/NULLIF Logic:** To handle empty display names and badge statuses.
6. **CASE Expressions:** To provide semantic statuses based on different conditions.
7. **Pagination Logic:** Using LIMIT & OFFSET to allow for intuitive browsing of results, simulating a "page" of results.
8. **Obscure Aggregation Filtering:** By utilizing the FILTER clause to separately count badge types. 

This is designed to be a complex but readable query, providing a deep analysis of post and user activities in the given schema.
