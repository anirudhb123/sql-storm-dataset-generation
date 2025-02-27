WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpvoteCount DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    rp.Rank,
    CASE 
        WHEN rp.UpvoteCount > 0 THEN 
            (100.0 * rp.UpvoteCount / NULLIF(rp.CommentCount + rp.UpvoteCount + rp.DownvoteCount, 0)) 
        ELSE 0 
    END AS UpvotePercentage,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN PostsTag pt ON t.Id = pt.TagId 
     WHERE pt.PostId = rp.PostId) AS Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;

This SQL query performs the following tasks:
1. **CTE (PostStatistics)**: Gathers aggregate data on posts created within the last year, including comment count, upvote count, and downvote count.
2. **RankedPosts**: Assigns a rank to posts based on the number of upvotes and comments, using the `ROW_NUMBER()` window function.
3. **Final Selection**: Selects the top 10 posts based on rank, calculates the upvote percentage, and aggregates tags associated with each post.
4. **NULL Logic**: Ensures division by zero is handled with `NULLIF` in the upvote percentage calculation. 
5. **String Aggregation**: Collects post tags into a single string using `STRING_AGG`. 

This query is suitable for performance benchmarking, as it showcases various SQL constructs and evaluates the efficiency of multiple joins and calculated expressions.
