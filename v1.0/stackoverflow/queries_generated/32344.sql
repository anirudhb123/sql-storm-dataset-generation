WITH RecursivePostPaths AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Starting with top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostPaths r ON p.ParentId = r.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActivityDate,
        AVG(DATEDIFF(MINUTE, ph.CreationDate, p.LastEditDate)) AS AvgEditTimeMinutes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.Depth,
        pa.VoteCount,
        pa.CommentCount,
        pa.LastActivityDate,
        pa.AvgEditTimeMinutes
    FROM 
        RecursivePostPaths p
    JOIN 
        PostActivity pa ON p.Id = pa.PostId
),
TopPosts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY Depth ORDER BY VoteCount DESC) AS Rank
    FROM 
        PostMetrics
)

SELECT 
    tp.Title,
    tp.VoteCount,
    tp.CommentCount,
    tp.LastActivityDate,
    tp.AvgEditTimeMinutes,
    COALESCE(pt.Name, 'No Type') AS PostTypeName
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.Id IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
WHERE 
    tp.Rank <= 5  -- Get top 5 posts by rank
ORDER BY 
    tp.Depth, tp.Rank;

