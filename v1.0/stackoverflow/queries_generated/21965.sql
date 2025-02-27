WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViewCount,
        AVG(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS AvgUpVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11, 12) -- Closing, Reopening, and Deletion history types
    WHERE 
        (p.ViewCount > 0 OR p.AcceptedAnswerId IS NOT NULL) -- Filter posts that have views or accepted answers
          AND (p.Title IS NOT NULL OR p.Body IS NOT NULL) -- Posts must have a title or body
          AND p.CreationDate < CURRENT_DATE -- Posts created before today
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.RankViewCount,
        CASE 
            WHEN rp.AvgUpVotes IS NULL THEN 0 -- handle NULL averages
            ELSE rp.AvgUpVotes
        END AS AvgUpVotes,
        rp.CommentTotal,
        rp.LastHistoryDate
    FROM 
        RankedPosts rp
    WHERE
        rp.RankViewCount <= 5 -- Top 5 posts per post type
),
FinalData AS (
    SELECT 
        fp.*,
        CASE 
            WHEN fp.CommentTotal > 5 THEN 'Popular'
            ELSE 'Less Popular'
        END AS PopularityStatus,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = fp.PostId AND v.VoteTypeId = 6) as CloseVoteCount -- Count of close votes on the post
    FROM 
        FilteredPosts fp
)

SELECT 
    f.*,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    CONCAT('Post ID: ', f.PostId, ' - Title: ', f.Title) AS PostDetails
FROM 
    FinalData f
LEFT JOIN 
    Posts p ON f.PostId = p.Id
WHERE
    COALESCE(f.CloseVoteCount, 0) = 0 -- Only shows posts with no close votes
ORDER BY 
    f.ViewCount DESC, f.LastHistoryDate DESC;

-- Performance Benchmarking with EXPLAIN ANALYZE before executing the query.
