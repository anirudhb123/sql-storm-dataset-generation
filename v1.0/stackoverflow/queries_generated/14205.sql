-- Performance Benchmarking Query
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        RecentPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.Rank
FROM 
    PostStats ps
WHERE 
    ps.Rank <= 10
ORDER BY 
    ps.Rank;
