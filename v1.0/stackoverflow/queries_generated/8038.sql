WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName as OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) as Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') as tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Tags,
    COALESCE(pht.Comment, 'No comments') as LastPostHistoryComment,
    MAX(pht.CreationDate) as LastPostHistoryDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory pht ON tp.PostId = pht.PostId
WHERE 
    pht.CreationDate IS NOT NULL
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.Tags, pht.Comment
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
