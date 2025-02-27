WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        p.ParentId,
        p.PostTypeId,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE 
            WHEN b.Class = 1 THEN 1
            WHEN b.Class = 2 THEN 0.5
            ELSE 0
        END) AS WeightedBadgeScore
    FROM 
        RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN Users u ON rp.PostId = u.Id 
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS uv ON rp.PostId = uv.PostId
    WHERE 
        rp.Rank <= 10 -- Get top 10 posts by type
    GROUP BY 
        rp.PostId, rp.Title, uv.UpVotes, uv.DownVotes
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.BadgeCount,
    pd.WeightedBadgeScore,
    coalesce(cpd.ClosedPostId, -1) AS ClosedPostId,
    cpd.CloseReason,
    cpd.ClosedBy,
    (CURRENT_TIMESTAMP - pd.CreationDate) AS AgeOfPost,
    (CASE 
        WHEN pd.Score > 0 THEN 'Popular'
        WHEN pd.Score < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END) AS PopularityStatus
FROM 
    PostDetails pd
LEFT JOIN ClosedPostDetails cpd ON pd.PostId = cpd.ClosedPostId
WHERE 
    (pd.UpVotes IS NOT NULL OR pd.DownVotes IS NOT NULL)
    AND pd.CommentCount > 0
ORDER BY 
    pd.WeightedBadgeScore DESC, pd.PostId;

This query showcases several advanced SQL constructs including:

- Common Table Expressions (CTEs) to break down the query logically.
- Window functions to rank posts by their creation date within their post type.
- Outer joins to bring together users and badges associated with posts.
- Complicated aggregations to calculate vote counts, comment counts, and a weighted score based on badge classifications.
- Conditional logic with a CASE statement to categorize posts based on their score.
- A handling of potentially closed posts along with a provision for cases when a post has not been closed. 

Additionally, it incorporates semantic edge cases such as filtering on null logic while maintaining a clear structure through carefully selected joins and aggregates.
