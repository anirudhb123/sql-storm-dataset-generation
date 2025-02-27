WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(pc.PostId) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    rp.CommentCount,
    PH.Comment AS EditComment,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        ELSE NULL
    END AS PostStatus,
    CASE 
        WHEN rp.Score = 0 THEN 'No Score'
        ELSE 'Scored'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory ph2 
        WHERE ph2.PostId = rp.PostId
    )
WHERE 
    rp.rn = 1
    AND COALESCE(rp.CommentCount, 0) > 0
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100

UNION ALL

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation,
    0 AS CommentCount,
    NULL AS EditComment,
    NULL AS PostStatus,
    'Deleted' AS ScoreStatus
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.Id NOT IN (SELECT PostId FROM RankedPosts)
    AND p.CreationDate < NOW() - INTERVAL '5 years'
    AND p.Score < 0
    AND p.IsDeleted = TRUE

ORDER BY 
    Score DESC, 
    CreationDate ASC

**Explanation of the query features included:**

1. **Common Table Expression (CTE)**: `RankedPosts` calculates ranks of posts based on `PostTypeId` and `Score`.
   
2. **Window Functions**: `ROW_NUMBER()` is used to rank posts, and `COUNT()` computes the total number of comments for each post.

3. **Outer Joins**: `LEFT JOIN` connects the `Posts` table with the `Comments` and `PostHistory` tables.

4. **Correlated Subqueries**: The subquery in the `LEFT JOIN` fetches the latest edit comment based on `CreationDate`.

5. **Complicated predicates**: Includes filters based on `CreationDate`, checks for `CommentCount`, and evaluates `Score`.

6. **UNION ALL**: Combines results for high-score posts with deleted posts that have a score below zero.

7. **String and NULL Logic**: The query handles observations for post status and score status via `CASE` statements.

8. **Unusual SQL Semantics**: The use of `LIMIT` in combination with `DISTINCT` and conditionally fetching the latest edits or deleted posts introduces less common SQL patterns. 

This elaborate SQL structure showcases advanced SQL features, providing insights into post performance while handling possible edge cases effectively.
