WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.FromDate,
        ph.UserId,
        COALESCE(u.DisplayName, 'Unknown') AS UserName,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.UserId
),
ClosedPostsWithDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerName,
        rp.Tags,
        cp.FirstClosedDate,
        cp.UserName AS CloserUser
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    cpwd.PostId,
    cpwd.Title,
    cpwd.ViewCount,
    cpwd.OwnerName,
    cpwd.Tags,
    cpwd.FirstClosedDate,
    cpwd.CloserUser,
    CASE 
        WHEN cpwd.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(
        (SELECT COUNT(DISTINCT v.UserId) 
         FROM Votes v 
         WHERE v.PostId = cpwd.PostId AND v.VoteTypeId = 2), 
        0) AS UpvoteCount
FROM 
    ClosedPostsWithDetails cpwd
ORDER BY 
    cpwd.ViewCount DESC, 
    cpwd.FirstClosedDate NULLS LAST;

-- Additional for performance benchmarking
EXPLAIN ANALYZE
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    SUM(CASE WHEN CommentCount > 0 THEN 1 ELSE 0 END) AS PostsWithComments
FROM 
    RankedPosts;
