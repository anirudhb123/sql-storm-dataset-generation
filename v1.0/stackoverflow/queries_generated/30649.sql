WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days') 
        AND p.Score IS NOT NULL
),
PostWithComments AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts r
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON r.PostId = c.PostId
),
PostHistoryDetails AS (
    SELECT
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pwc.Title,
    pwc.CreationDate,
    pwc.Score,
    pwc.ViewCount,
    pwc.OwnerDisplayName,
    pwc.CommentCount,
    COALESCE(phd.LastClosedDate, 'Never') AS LastClosedDate,
    COALESCE(phd.LastReopenedDate, 'Never') AS LastReopenedDate,
    CASE 
        WHEN pwc.Score > 100 THEN 'Hot'
        WHEN pwc.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'Average'
    END AS Popularity
FROM 
    PostWithComments pwc
JOIN 
    PostHistoryDetails phd ON pwc.PostId = phd.PostId
WHERE 
    pwc.Rank <= 5
ORDER BY 
    pwc.Score DESC;

This SQL query does several interesting things:

1. **Common Table Expressions (CTEs)**: It uses three CTEs to structure the query:
   - `RankedPosts`: Ranks posts within their type by score for recent posts.
   - `PostWithComments`: Joins the ranking with the number of comments, allowing to handle missing data gracefully with `COALESCE`.
   - `PostHistoryDetails`: Fetches the last closed and reopened dates for each post.

2. **Window Functions**: The query employs `ROW_NUMBER()` to rank posts based on scores.

3. **Outer Joins**: It utilizes a left join to include posts that may not have comments.

4. **Complicated Predicates**: It filters posts to retrieve only the top 5 ranked posts based on score that are created in the last 30 days.

5. **NULL Logic**: It uses `COALESCE` to handle NULL values for comments and the last closed/reopened dates, providing fallback values.

6. **String Expressions and Conditional Logic**: It includes a CASE statement to classify posts into different popularity categories based on their score.

This query can serve well for performance benchmarking while demonstrating complex interactions within the schema.
