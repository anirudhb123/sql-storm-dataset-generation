WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
    AND 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM STRING_SPLIT(tp.Tags, ',') t) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.Id = c.PostId
LEFT JOIN 
    Votes v ON tp.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod
GROUP BY 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
