WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, OwnerDisplayName, CommentCount, UpvoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.*,
    pt.Name AS PostType,
    JSON_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
GROUP BY 
    tp.PostId, pt.Name
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
