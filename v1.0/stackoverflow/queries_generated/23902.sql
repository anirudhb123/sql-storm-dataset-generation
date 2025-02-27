WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentTotal,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteTotal,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPostTypes AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
    HAVING
        COUNT(*) > 5
)
SELECT 
    pt.Name AS PostType,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    rp.CommentTotal,
    rp.UpvoteTotal,
    rp.DownvoteTotal
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
JOIN 
    TopPostTypes tpt ON pt.Id = tpt.PostTypeId
WHERE 
    rp.Rank <= 5
ORDER BY 
    pt.Name, rp.Rank;

In this query:

1. **Common Table Expressions (CTEs)** are used to first rank posts by their scores and count comment totals in `RankedPosts`, and to filter the post types with more than 5 posts in `TopPostTypes`.
2. The use of `ROW_NUMBER()` provides a ranking for each post within its type, sorted by score and creation date.
3. The joining of `Votes` table allows counting upvotes and downvotes, demonstrating conditional aggregation.
4. A `LEFT JOIN` ensures all posts have the potential to show, even if they have no associated comments or votes.
5. The query includes a filter to only include posts created within the last 6 months, showcasing a usage of time functions.
6. Results are filtered to show only the top 5 posts per type based on their score.
7. The final output provides useful analytics such as total votes and comments count, grouped by post types.

This query can be used for performance benchmarking due to its complexity involving multiple joins, aggregates, and window functions.
