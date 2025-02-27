WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rn <= 5
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    JOIN 
        PostLinks pl ON pl.PostId = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Author,
    tp.CommentCount,
    (SELECT STRING_AGG(pt.TagName, ', ') FROM PopularTags pt WHERE pt.TagCount >= 1 AND pt.TagCount <= 10) AS PopularTags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
