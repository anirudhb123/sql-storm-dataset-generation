
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
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0))
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
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
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON EXISTS (SELECT 1 FROM Posts WHERE PostId = tp.PostId AND PostTypeId = pt.Id)
LEFT JOIN 
    (SELECT 
         SUBSTRING(pp.Tags, 2, LEN(pp.Tags) - 2) AS TagName,
         pp.Id AS PostId
     FROM 
         Posts pp) AS t ON t.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.OwnerReputation, tp.CommentCount, pt.Name
ORDER BY 
    tp.Score DESC;
