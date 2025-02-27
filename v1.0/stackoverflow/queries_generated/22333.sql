WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
MostCommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
HighScorePosts AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.ViewCount,
        mp.CreationDate,
        mp.Score,
        mp.CommentCount,
        EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = mp.PostId 
              AND v.VoteTypeId = 2 
              AND v.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        ) AS HasRecentUpvote
    FROM 
        MostCommentedPosts mp
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.ViewCount,
    hp.CreationDate,
    hp.Score,
    hp.CommentCount,
    CASE 
        WHEN hp.HasRecentUpvote = TRUE THEN 'Popular'
        ELSE 'Needs Attention'
    END AS PostStatus,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId = (SELECT WikiPostId FROM Tags WHERE Id IN (SELECT DISTINCT unnest(string_to_array(hp.Title, ' ')))) LIMIT 5) AS RelatedTags
FROM 
    HighScorePosts hp
ORDER BY 
    hp.Score DESC, hp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;

This SQL query showcases a variety of SQL features and constructs:

1. **Common Table Expressions (CTEs)**: The query incorporates multiple CTEs to organize and filter relevant posts based on different criteria.

2. **Window Functions**: It uses `ROW_NUMBER()` to rank the posts based on their score and view count.

3. **Outer Joins**: A `LEFT JOIN` is employed to gather comment counts while allowing posts with zero comments to still be included.

4. **Correlated Subqueries**: The `EXISTS` clause checks for recent upvotes within the last 30 days for each post in the `HighScorePosts` CTE.

5. **Aggregate Functions**: `COUNT(*)` is used to summate the number of comments, and `STRING_AGG` (or equivalent) gathers tag names as a concatenated string.

6. **NULL Handling**: The `COALESCE` function ensures that even posts without comments show a comment count of zero.

7. **Complex Conditions**: The query includes a `CASE` statement to establish logical descriptions for post status based on voting activity.

8. **Bizarre Logic**: The query defines related tags based on the title's words, showcasing unusual semantic practices in tag association.

The overarching goal of the query is to identify and characterize the most commented and highest-scoring posts within the last year, thus serving as a performance benchmarking exercise.
