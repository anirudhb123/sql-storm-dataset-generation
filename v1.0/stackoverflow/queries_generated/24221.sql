WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsAggregated,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments' 
            ELSE 'No Comments' 
        END AS CommentStatus,
        CASE 
            WHEN rp.UpvoteCount > rp.DownvoteCount THEN 'Favorably Received'
            WHEN rp.UpvoteCount < rp.DownvoteCount THEN 'Unfavorably Received'
            ELSE 'Neutral'
        END AS ReceptionStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentStatus,
    fp.ReceptionStatus,
    CASE 
        WHEN fp.TagsAggregated IS NULL THEN 'No Tags'
        ELSE STRING_AGG(fp.TagsAggregated, ', ')
    END AS Tags
FROM 
    FilteredPosts fp
LEFT OUTER JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
    AND ph.CreationDate = (
        SELECT MAX(ph2.CreationDate)
        FROM PostHistory ph2
        WHERE ph2.PostId = fp.PostId
    )
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12) -- Considering specific post history types
ORDER BY 
    fp.Score DESC NULLS LAST, 
    fp.CreationDate DESC;
This SQL query performs the following operations:

1. Creates a Common Table Expression (CTE) called `RankedPosts` that retrieves posts created in the last year. It ranks them by score (and creation date) within their post types and aggregates tags, comments, and vote counts.

2. Another CTE, `FilteredPosts`, is created to filter the top 5 posts per type. It also categorizes each post based on the presence of comments and the balance of upvotes and downvotes.

3. Finally, the main select query retrieves fields from `FilteredPosts`, incorporates the most recent activity from `PostHistory` using a correlated subquery, and orders results by score and creation date. 

The query includes outer joins, CTEs, window functions, complex case statements, and carefully handles NULL logic and aggregations using STRING_AGG.
