
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
        AND p.Score IS NOT NULL
        AND p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.ViewCount,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    (SELECT COUNT(v.Id) 
     FROM Votes v 
     WHERE v.PostId = t.PostId 
     AND v.VoteTypeId IN (2, 3, 7) 
    ) AS VoteCount,
    (SELECT LISTAGG(DISTINCT tag.TagName, ', ') 
     FROM Tags tag 
     WHERE tag.TagName IN (
         SELECT TRIM(split_tags.Value) 
         FROM TABLE(FLATTEN(INPUT => SPLIT(t.Title, ' '))) AS split_tags
     )
    ) AS AssociatedTags
FROM 
    TopPosts t
LEFT JOIN 
    Users u ON t.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY 
    t.Score DESC, 
    t.ViewCount DESC
LIMIT 10;
