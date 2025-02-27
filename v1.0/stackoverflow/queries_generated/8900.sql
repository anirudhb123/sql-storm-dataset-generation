WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.Score DESC,
        rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CommentCount,
    pt.Name AS PostTypeName,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId IN (SELECT PostId FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN 
    STRING_TO_ARRAY(substring((SELECT Tags FROM Posts pp WHERE pp.Id = tp.PostId), 2, length((SELECT Tags FROM Posts pp WHERE pp.Id = tp.PostId))-2), '><') AS t
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.OwnerReputation, tp.CommentCount, pt.Name
ORDER BY 
    tp.Score DESC;
