WITH RecursivePostChain AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Start with Answers

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        rpc.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostChain rpc ON p.Id = rpc.ParentId
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(DATEDIFF(CAST(CURRENT_TIMESTAMP AS DATE), c.CreationDate)), 0) AS AvgDaysToComment
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.TotalBounty,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    ps.AvgDaysToComment,
    COALESCE(cp.CreationDate, 'No Closure') AS ClosureDate,
    COALESCE(cp.UserDisplayName, 'Not Closed') AS ClosedBy,
    RANK() OVER (ORDER BY ps.Upvotes DESC) AS RankByUpvotes,
    DENSE_RANK() OVER (PARTITION BY ps.CommentCount ORDER BY ps.TotalBounty DESC) AS RankByCommentCountBounty
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.TotalBounty DESC, 
    ps.Upvotes DESC
LIMIT 100;
