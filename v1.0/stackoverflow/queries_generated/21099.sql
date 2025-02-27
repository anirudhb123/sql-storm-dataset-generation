WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(COALESCE(c.Score, 0)) OVER (PARTITION BY p.Id) AS TotalCommentsScore,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment,
        COALESCE(pp.TotalCommentsScore, 0) AS TotalCommentsScore
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts pp ON ph.PostId = pp.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15) /* Considering only close and delete events */
),
FilteredTopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.rn = 1 THEN 'Latest Post'
            ELSE 'Older Post'
        END AS PostRank
    FROM 
        RankedPosts rp
    WHERE 
        (rp.TotalCommentsScore > 50 OR rp.UpvoteCount - rp.DownvoteCount > 10)
),
CombinedResults AS (
    SELECT 
        ft.PostId,
        ft.Title,
        ft.CreationDate,
        ft.ViewCount,
        ft.Score,
        ft.PostRank,
        phwc.HistoryCreationDate,
        phwc.Comment
    FROM 
        FilteredTopPosts ft
    FULL OUTER JOIN 
        PostHistoryWithComments phwc ON ft.PostId = phwc.PostId
)
SELECT 
    cr.*,
    COALESCE(phwc.Comment, 'No history comments available') AS CommentDetails,
    (SELECT STRING_AGG(Tags.TagName, ', ') 
     FROM Tags 
     WHERE Tags.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(Posts.Tags, 2, LENGTH(Posts.Tags) - 2), '><')::int[])) 
                        FROM Posts 
                        WHERE Posts.Id = cr.PostId)) AS RelatedTags
FROM 
    CombinedResults cr
ORDER BY 
    cr.Score DESC, cr.ViewCount DESC NULLS LAST
LIMIT 100;

-- Checking NULL logic: 
-- This query retrieves posts published in the last year that have significant comment engagement or a high score.
-- It uses window functions to rank posts by users while considering their total comment score and upvotes/downvotes.
-- Additionally, it augments the results with relevant history information when available, and gathers associated tags.
-- Full outer joins ensure that we capture all posts, combining those with and without historical entries.
