WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
      AND 
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.Views,
        rp.Rank,
        CASE 
            WHEN cp.LastClosedDate IS NOT NULL AND cp.LastClosedDate > DATEADD(MONTH, -3, GETDATE()) THEN 'Recently Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.ViewCount,
    ps.Rank,
    ps.PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostStats ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
LEFT JOIN 
    LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_list ON TRUE
LEFT JOIN 
    Tags t ON tag_list = t.TagName
WHERE 
    ps.Rank <= 10 -- top 10 posts per type
GROUP BY 
    ps.PostId, ps.Title, ps.Score, ps.CommentCount, ps.ViewCount, ps.Rank, ps.PostStatus
HAVING 
    COUNT(t.Id) > 0 OR ps.PostStatus = 'Recently Closed'
ORDER BY 
    ps.Rank, ps.Score DESC;

This SQL query performs the following operations:

1. **CTEs**: It uses Common Table Expressions (CTEs) to rank posts by their score and gather relevant statistics, including comment count and vote totals.

2. **Outer Joins**: It utilizes `LEFT JOIN` operations to associate comments and votes while retrieving the posts.

3. **Correlated Subqueries**: There's a nested operation within the second CTE for determining the last closed date of a post.

4. **Window Functions**: It employs `ROW_NUMBER()` to rank posts within their post type group.

5. **Set Operators**: The query finds tags relating to the posts using linked data through additional lateral joins.

6. **STRING_AGG**: This function aggregates the tags for each post into a single string.

7. **Complicated Predicates**: Filtering based on the post's age and status while also requiring that posts with no tags are excluded unless they are marked as recently closed.

8. **NULL Logic**: It handles cases where the view count and other fields might be NULL, ensuring it still provides meaningful output.

The overall structure allows for a rich analysis of posts while also addressing potential edge cases regarding post statuses, associations, and various filtering criteria.
