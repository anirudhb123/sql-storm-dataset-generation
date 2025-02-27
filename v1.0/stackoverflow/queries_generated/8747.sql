WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.TAGS) - 2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
    HAVING 
        COUNT(*) > 1
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.ViewCount,
    tp.Tags,
    CASE 
        WHEN tp.CommentCount = 0 THEN 'No Comments'
        WHEN tp.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
        ELSE 'Many Comments'
    END AS CommentCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
