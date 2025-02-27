WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.Id = tag::int
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.rn,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        tp.Score,
        tp.ViewCount,
        tp.Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.CreationDate,
    fm.CommentCount,
    fm.Score,
    fm.ViewCount,
    fm.Tags,
    CASE 
        WHEN fm.Score > 100 THEN 'Hot'
        WHEN fm.ViewCount > 1000 THEN 'Trending'
        ELSE 'Standard'
    END AS PostStatus
FROM 
    FinalMetrics fm
ORDER BY 
    fm.Score DESC, fm.ViewCount DESC;
