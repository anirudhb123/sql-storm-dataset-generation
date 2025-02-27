WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -2, CURRENT_TIMESTAMP) 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.OwnerDisplayName, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.OwnerDisplayName, 
    tp.Score, 
    tp.CommentCount, 
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    UNNEST(string_to_array((SELECT Tags FROM Posts WHERE Id = tp.PostId), ',')) AS tag ON TRUE
JOIN 
    Tags t ON t.TagName = tag
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.CommentCount
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
