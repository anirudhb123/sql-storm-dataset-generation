WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        OwnerDisplayName, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5 -- Top 5 per PostType
)
SELECT 
    tp.Title, 
    tp.OwnerDisplayName, 
    tp.Score, 
    tp.CreationDate, 
    pt.Name AS PostTypeName, 
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN 
    STRING_TO_ARRAY(tp.Tags, ',') AS tag ON TRUE -- Extract Tags assuming tags are stored as a comma-separated string
LEFT JOIN 
    Tags t ON t.TagName = tag
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.Score, tp.CreationDate, pt.Name
ORDER BY 
    tp.CreationDate DESC;
