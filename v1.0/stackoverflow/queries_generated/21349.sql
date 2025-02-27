WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate <= NOW() -- Only consider posts created in the past
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosePostReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    ts.TagName,
    ts.PostCount,
    ts.AvgViewCount,
    ue.DisplayName,
    ue.Upvotes,
    ue.Downvotes,
    ue.CommentCount,
    ue.BadgeCount,
    cpr.CloseReasonCount,
    cpr.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON ts.PostCount > 1
LEFT JOIN 
    UserEngagement ue ON ue.UserId = rp.PostId
LEFT JOIN 
    ClosePostReasons cpr ON cpr.PostId = rp.PostId
WHERE 
    rp.Rank <= 10  -- Top 10 posts by view count within their post type
    AND (rp.PostTypeId = 1 OR rp.PostTypeId = 2)  -- Only Questions or Answers
ORDER BY 
    rp.ViewCount DESC, ue.Upvotes DESC NULLS LAST
LIMIT 100; -- Limit to top 100 results
This elaborate SQL query showcases multiple advanced constructs, including Common Table Expressions (CTEs), outer joins, aggregates, and conditional logic while also handling NULLs. The query focuses on ranked posts filtered by certain criteria, tag statistics, user engagement metrics, and reasons for post closures.
