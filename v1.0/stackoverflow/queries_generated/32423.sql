WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        CAST(NULL AS text) AS ParentTitle,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.OwnerUserId,
        r.Title AS ParentTitle,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePosts r ON a.ParentId = r.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ParentTitle,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    CASE 
        WHEN bp.BadgeCount IS NULL THEN 0 
        ELSE bp.BadgeCount 
    END AS BadgeCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM 
    RecursivePosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) bp ON u.Id = bp.UserId
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
WHERE 
    rp.CreationDate >= DATEADD(day, -30, GETDATE())
GROUP BY 
    rp.PostId, rp.Title, rp.ParentTitle, rp.ViewCount, rp.Score, 
    u.DisplayName, u.Reputation, bp.BadgeCount
HAVING 
    AVG(rp.Score) OVER () > 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation:
1. **Common Table Expression (CTE)**: The query uses a recursive CTE (`RecursivePosts`) to gather questions and their corresponding answers, allowing us to maintain a hierarchy within the posts.
  
2. **Main Query**: The main query selects various details about the posts, such as title, view count, score, and the owner's reputation, along with a count of comments and related posts.

3. **LEFT JOINs**: The query uses multiple `LEFT JOINs` to connect with `Users`, `Badges`, `Comments`, and `PostLinks` to aggregate relevant information connected to each post.

4. **Filtering**: There’s a `WHERE` condition to filter for posts created in the last 30 days.

5. **HAVING with Window Function**: It includes a `HAVING` clause that checks for posts whose average score is greater than 5, leveraging window functions.

6. **Pagination**: The query implements pagination to return only the top 10 posts ordered by score and view count. 

7. **NULL Logic**: The logic includes handling potential `NULL` values in badges counts using a `CASE` statement.

This query is designed to benchmark performance through its complexity and use of various SQL constructs.
