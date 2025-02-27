WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(
            (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = p.OwnerUserId), 
            0
        ) AS OwnerAvgScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score
),
TopPosts AS (
    SELECT 
        pwc.*,
        CASE 
            WHEN pwc.Score > 50 AND pwc.CommentCount > 10 THEN 'High Engagement'
            WHEN pwc.Score BETWEEN 20 AND 50 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PostsWithComments pwc
    WHERE 
        pwc.Rank <= 5  -- getting top 5 posts per user
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.PositiveComments,
    tp.EngagementLevel,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM Tags t 
        JOIN LATERAL 
            (SELECT UNNEST(STRING_TO_ARRAY(LEFT(p.Tags, LENGTH(p.Tags) - 2), '><')) AS TagName 
             WHERE t.TagName IS NOT NULL) AS tag_list 
        ON t.TagName = tag_list.TagName 
     WHERE p.Id = tp.PostId) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.PostId
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

This SQL query showcases various advanced SQL features like Common Table Expressions (CTEs), window functions, correlated subqueries, complex filtering with `CASE` statements, and string aggregation. 

1. **CTEs** are used to break down the query into manageable sections.
2. **Window functions** are utilized to rank posts per user based on their scores.
3. **LEFT JOIN** with aggregation to count comments and derive engagement metrics.
4. **Correlated subqueries** are employed to get upvotes and downvotes while allowing flexibility in filtering.
5. **String manipulation and aggregation** to provide a consolidated list of tags related to each post.

This query provides a rich dataset for analyzing post performance, user engagement, and interaction metrics while demonstrating complex SQL capabilities.
