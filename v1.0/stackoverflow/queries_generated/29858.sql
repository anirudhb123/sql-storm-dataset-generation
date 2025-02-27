WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Upvotes,
        Downvotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 100
),
PostStats AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Upvotes) AS AvgUpvotes,
        AVG(Downvotes) AS AvgDownvotes,
        AVG(CommentCount) AS AvgCommentCount
    FROM 
        FilteredPosts
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Upvotes,
    fp.Downvotes,
    fp.CommentCount,
    ps.AvgViewCount,
    ps.AvgUpvotes,
    ps.AvgDownvotes,
    ps.AvgCommentCount,
    CASE 
        WHEN fp.ViewCount > ps.AvgViewCount THEN 'Above Average Views'
        ELSE 'Below Average Views'
    END AS ViewCountComparison,
    CASE 
        WHEN fp.Upvotes > ps.AvgUpvotes THEN 'Above Average Upvotes'
        ELSE 'Below Average Upvotes'
    END AS UpvotesComparison,
    CASE 
        WHEN fp.Downvotes > ps.AvgDownvotes THEN 'Above Average Downvotes'
        ELSE 'Below Average Downvotes'
    END AS DownvotesComparison,
    CASE 
        WHEN fp.CommentCount > ps.AvgCommentCount THEN 'Above Average Comments'
        ELSE 'Below Average Comments'
    END AS CommentCountComparison
FROM 
    FilteredPosts fp, 
    PostStats ps
ORDER BY 
    fp.ViewCount DESC;
