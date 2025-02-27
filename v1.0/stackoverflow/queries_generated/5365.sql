WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.*,
    ph.UserDisplayName AS LastEditedBy,
    ph.CreationDate AS LastEditedDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(ph2.CreationDate)
        FROM PostHistory ph2
        WHERE ph2.PostId = tp.PostId
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
