
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    pt.TagName,
    pt.PostCount
FROM 
    TopPosts tp
LEFT JOIN 
    PopularTags pt ON pt.PostCount = (
        SELECT MAX(PostCount) FROM PopularTags
    )
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
