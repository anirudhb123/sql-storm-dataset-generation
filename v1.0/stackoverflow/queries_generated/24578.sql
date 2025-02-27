WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankDate,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.VoteCount,
    rp.CommentCount,
    CASE 
        WHEN rp.RankScore = 1 THEN 'Top Score'
        WHEN rp.RankDate = 1 THEN 'Latest Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    ISNULL((SELECT COUNT(*) 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11)), 0) AS CloseOpenCount,
    STRING_AGG(DISTINCT CONVERT(VARCHAR, t.TagName), ', ') AS TagsUsed
FROM 
    RankedPosts rp
LEFT JOIN 
    STRING_SPLIT(rp.Tags, ',') AS t ON CAST(t.value AS varchar(35)) IN (SELECT TagName FROM Tags)
WHERE 
    rp.VoteCount > 10 OR rp.CommentCount > 5
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.RankScore, rp.RankDate
HAVING 
    COUNT(DISTINCT t.Value) > 0
ORDER BY 
    CASE 
        WHEN PostCategory = 'Top Score' THEN 1
        ELSE 2
    END,
    rp.Score DESC;

This query performs the following elaborate operations:
1. Uses a Common Table Expression (CTE) named `RankedPosts` to aggregate post data, including score, view count, and rank based on both score and creation date, while also counting votes and comments associated with each post.
2. Incorporates a correlated subquery to count how many times each post has been closed or opened through the `PostHistory` table.
3. Leverages `STRING_AGG` to create a comma-separated list of tags associated with each post using `STRING_SPLIT`.
4. Includes complex predicates to filter posts based on vote count and comment count.
5. Utilizes a `CASE` statement to categorize posts based on their rank and adds a final ordering clause to prioritize post categories, demonstrating complexity in both logic and semantics.
